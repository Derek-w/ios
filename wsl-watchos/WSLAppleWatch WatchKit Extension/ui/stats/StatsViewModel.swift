//
//  StatsViewModel.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/14/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CocoaLumberjack

class StatsViewModel {
    private var wslApiService: WSLApiService
    private var wslPushService: WSLPushService
    private var disposeBag = DisposeBag()
    private var athlete: Athlete?
    private var event: Event?
    private var lastActiveFlag = false
    private var hasOfflineApiError = false
    private var networkFailingCount = 0
    private var offlineTimer: Timer?
    
    var error = PublishRelay<Bool>()
    var title = BehaviorRelay<String?>(value: nil)
    var targetScoreValue = BehaviorRelay<String?>(value: nil)
    var targetScoreLabel = BehaviorRelay<String?>(value: nil)
    var priority = BehaviorRelay<[Priority]>(value: [])
    var totalScoreValue = BehaviorRelay<Double>(value: 0.0)
    var topScoresValue = BehaviorRelay<[Double]>(value: [])
    var status = BehaviorRelay<String?>(value: nil)
    var endUnixTimeStamp = BehaviorRelay<Double?>(value: 0.0)
    var isOfflineMode = BehaviorRelay<Bool>(value: false)
    var takeoverMode = BehaviorRelay<TakeoverType>(value: .none)
    var heatPriority = BehaviorRelay<Bool>(value: false)
    
    init() {
        self.wslApiService = SwinjectUtil.sharedInstance.container.resolve(WSLApiService.self)!
        self.wslPushService = SwinjectUtil.sharedInstance.container.resolve(WSLPushService.self)!
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceivedNotification(notification:)), name: Notification.Name(Constant.EVENT_STATUS_UPDATE_KEY), object: nil)
    }
    
    init(wslPushService: WSLPushService, wslApiService: WSLApiService) {
        self.wslPushService = wslPushService
        self.wslApiService = wslApiService
    }
    
    func loadModel(event: Event, athlete: Athlete) {
        self.event = event
        self.athlete = athlete
        // Start monitoring locations
        LocationService.sharedInstance.startTrackingLocation()
        
        DDLogWarn("Starting HTTP Polling");
        getEventStatus()
        
        if let roundId = athlete.roundId {
            logAthleteEventWatchUsage(eventId: event.eventId,
                                  athleteId: athlete.athleteId,
                                  roundId: roundId,
                                  heatNumber: athlete.heatNumber)
        }
    }
    
    func getEventStatus() {
        guard let event = event, let athlete = athlete else { return }
        wslPushService.getEventStatus(event.eventId, athleteId: athlete.athleteId).subscribe { [weak self] event in
            guard let strongSelf = self else { return }
            if let apiError = event.error {
                DDLogError("getEventStatus api error: \(apiError.localizedDescription)")
                if strongSelf.networkFailingCount < Constant.MAX_NETWORK_FAILURE_ALLOWED {
                    strongSelf.networkFailingCount += 1
                }
                if apiError.localizedDescription == "The Internet connection appears to be offline." ||
                    apiError.localizedDescription == "The request timed out.",
                        strongSelf.hasOfflineApiError == false {
                        strongSelf.hasOfflineApiError = true
                        strongSelf.logDisconnectionLocation()
                }
                strongSelf.acceptError()
            } else if let (eventStatus) = event.element {
                strongSelf.networkFailingCount = 0
                strongSelf.offlineTimer?.invalidate()
                strongSelf.acceptStats(eventStatus)
            }
            
            if event.isStopEvent {
                if (Constant.STAT_POLL_INTERVAL > 0){
                    // Schedule another call if setting is enabled
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constant.STAT_POLL_INTERVAL) {
                        strongSelf.getEventStatus()
                    }
                }
            }
            
        }.disposed(by: disposeBag)
    }
    
    private func acceptError() {
        error.accept(true)
        if isOfflineMode.value == false && self.networkFailingCount >= Constant.MAX_NETWORK_FAILURE_ALLOWED {
            isOfflineMode.accept(true)
        }
    }
    
    private func acceptStats(_ eventStatus: EventStatus) {
        DDLogWarn("Status Arrive \(eventStatus)")
        title.accept("")
                        
        targetScoreValue.accept(eventStatus.targetScoreValue)
        targetScoreLabel.accept(eventStatus.targetScoreLabel)
        priority.accept(processPriority(eventStatus.priority))
        totalScoreValue.accept(eventStatus.totalScoreValue)
        topScoresValue.accept(eventStatus.topScoresValue)
        status.accept(eventStatus.status)
        endUnixTimeStamp.accept(eventStatus.endUnixTimeStamp)
        heatPriority.accept(eventStatus.heatPriority ?? false)
        if isOfflineMode.value == true {
            hasOfflineApiError = false
            isOfflineMode.accept(false)
        }
        
        if isInterference(eventStatus.priority) {
            takeoverMode.accept(.interference)
        } else if isDisqualified(eventStatus.priority) {
            takeoverMode.accept(.disqualified)
        } else {
            takeoverMode.accept(.none)
        }
    }
    
    func isInterference(_ priorities: [Priority]) -> Bool {
        let p = priorities.filter({ $0.athleteId == self.athlete?.athleteId && $0.text == "INT" })
        
        return !p.isEmpty
    }
    
    private func isDisqualified(_ priorities: [Priority]) -> Bool {
        let p = priorities.filter({ $0.athleteId == self.athlete?.athleteId && $0.text == "DQ" })
        
        return !p.isEmpty
    }
    
    private func processPriority(_ priorities: [Priority]) -> [Priority] {
        guard priorities.count != 0 else { return [] }
        
        var p = priorities.filter({ $0.athleteId == self.athlete?.athleteId && $0.text == "P" })
        
        if !p.isEmpty {
            return p
        }
        
        p = priorities.filter({ $0.athleteId == self.athlete?.athleteId && $0.text == "DQ" })
        
        return p.isEmpty ? priorities : p
    }
    
    func isMyNumber(numStr: String?) -> Bool {
        return numStr == self.athlete?.athleteId
    }
    
    @objc func didReceivedNotification(notification: Notification) {
        guard let athlete = athlete else { return }
        if let userInfo = notification.userInfo as? [String: Any],
            let eventStatus = EventStatus.decodeEventStatus(userInfo),
            eventStatus.athleteId == athlete.athleteId {
            acceptStats(eventStatus)
        }
    }
    
    private func logDisconnectionLocation() {
        let logPrefix = "EventId: \(self.event!.eventId) Athlete: \(self.athlete!.athleteId) HeatNumber: \( self.athlete!.heatNumber)"
        guard let locValue = LocationService.sharedInstance.getCurrentLocation()?.coordinate else { return }
        DDLogWarn("\(logPrefix), Disconnected location: latitude - \(locValue.latitude), longtitude - \(locValue.longitude)")
        self.offlineTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] timer in
            if self?.hasOfflineApiError == true {
                self?.isOfflineMode.accept(true)
            }
        }
    }
    
    func logAthleteEventWatchUsage(eventId: String, athleteId: String, roundId: String, heatNumber: Int) {
        self.wslApiService.logAthleteEventWatchUsage(eventId: eventId,
                                                     athleteId: athleteId,
                                                     roundId: roundId,
                                                     heatNumber: heatNumber).subscribe { event in
                                                        if let apiError = event.error {
                                                            DDLogError("logAthleteEventWatchUsage api error: \(apiError.localizedDescription)")
                                                        } else if event.element != nil {
                                                            DDLogError("logAthleteEventWatchUsage success")
                                                        }
                                                    }.disposed(by: disposeBag)
    }
    
    deinit {
        LocationService.sharedInstance.stopTrackingLocation()
    }
    
}
