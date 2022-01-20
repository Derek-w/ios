//
//  StatsInterfaceController.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/14/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import WatchKit
import CoreLocation
import HealthKit
import CocoaLumberjack
import CoreLocation

class StatsInterfaceController: RxInterfaceController, HKWorkoutSessionDelegate {
   
    
    private var statsViewModel: StatsViewModel!
    private var heartbeatHidden = false
    private var workoutSession: HKWorkoutSession?
    private var loadedInitialStats = false
    private var workoutInProgress = false
    private var alertViewDisplayed = false
    private var savedUnixTimeStamp: TimeInterval = 0
    private var hasPriority = false
    private var isDisqualified = false
    private var hadTakeoverType: TakeoverType = .none
    
    @IBOutlet weak var countdownTimer: WKInterfaceTimer!
    @IBOutlet weak var heatScoreTitle: WKInterfaceLabel!
    @IBOutlet weak var scoreLabel: WKInterfaceLabel!
    @IBOutlet weak var top2ScoresLabel: WKInterfaceLabel!
    @IBOutlet weak var needsScoreLabel: WKInterfaceLabel!
    @IBOutlet weak var needsDetailLabel: WKInterfaceLabel!
    
    @IBOutlet weak var heatPulsingView: WKInterfaceSKScene!
    @IBOutlet weak var ownPriorityView: WKInterfaceGroup!
    @IBOutlet weak var ownPriorityLabel: WKInterfaceLabel!
    @IBOutlet weak var priorityView: WKInterfaceGroup!
    @IBOutlet weak var priorityGroup1: WKInterfaceGroup!
    @IBOutlet weak var boarderView1: WKInterfaceGroup!
    @IBOutlet weak var priorityGroup2: WKInterfaceGroup!
    @IBOutlet weak var boarderView2: WKInterfaceGroup!
    @IBOutlet weak var priorityGroup3: WKInterfaceGroup!
    @IBOutlet weak var boarderView3: WKInterfaceGroup!
    @IBOutlet weak var priorityGroup4: WKInterfaceGroup!
    @IBOutlet weak var boarderView4: WKInterfaceGroup!
    
    @IBOutlet weak var priorityLabel1: WKInterfaceLabel!
    @IBOutlet weak var priorityLabel2: WKInterfaceLabel!
    @IBOutlet weak var priorityLabel3: WKInterfaceLabel!
    @IBOutlet weak var priorityLabel4: WKInterfaceLabel!
    
    @IBOutlet weak var offlineWaveView: WKInterfaceGroup!
    @IBOutlet weak var offlineWaveImage: WKInterfaceImage!
    @IBOutlet weak var fullGroup: WKInterfaceGroup!
    @IBOutlet weak var loadingGroup: WKInterfaceGroup!
    @IBOutlet weak var loadingLabel: WKInterfaceLabel!

    var athlete: Athlete?
    var event: Event?
    
    var priorityGroups : [WKInterfaceGroup] = []
    var priorityLabels : [WKInterfaceLabel] = []
    var boarderViews: [WKInterfaceGroup] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.statsViewModel = StatsViewModel()
                
        NotificationCenter.default.addObserver(self, selector: #selector(self.dismissActiveCompanionView), name: Notification.Name(Constant.COMPANION_SESSION_ENDED_KEY), object: nil)
        
        guard let (event, athlete, hadTakeoverType) = context as? (Event, Athlete, TakeoverType) else { return }
        
        self.athlete = athlete
        self.event = event
        self.hadTakeoverType = hadTakeoverType
        setTitle("\(athlete.displayName)")
        bindViews()
    }
    
    override func willActivate() {
        super.willActivate()
        
        priorityGroups = [priorityGroup1!, priorityGroup2!, priorityGroup3!, priorityGroup4!]
        priorityLabels = [priorityLabel1!, priorityLabel2!, priorityLabel3!, priorityLabel4!]
        boarderViews = [boarderView1!, boarderView2!, boarderView3!, boarderView4!]
        
        if (!loadedInitialStats) {
            self.loadedInitialStats.toggle()
            configurePreloadData()
        }
        offlineWaveView.setHidden(true)
        offlineWaveImage.setImageNamed("wave")
    }
             
    // MARK: - notifications
    
    @objc func dismissActiveCompanionView() {
        self.stopWorkout()
        self.dismissAndReturnToRoot()
    }
    
    
    // MARK: - private
    private func bindViews() {
        guard let viewModel = statsViewModel, let event = self.event, let athlete = self.athlete else { return }
        
        disposeBag.insertAll(all:                    
                        
            viewModel.targetScoreValue.subscribe { [weak self] event in
                guard let strongSelf = self, let element = event.element, let text = element else { return }
                strongSelf.needsScoreLabel.setText(text)
            },
            viewModel.targetScoreLabel.subscribe { [weak self] event in
                guard let strongSelf = self, let element = event.element, let text = element else { return }
                strongSelf.needsDetailLabel.setText(text)
            },
            viewModel.endUnixTimeStamp.subscribe { [weak self] event in
                guard let strongSelf = self, let element = event.element, let endUnixTimeStamp = element else { return }
                strongSelf.handleEndUnixTimeStampUpdate(endUnixTimeStamp)
            },
            viewModel.status.subscribe { [weak self] event in
                guard let strongSelf = self, let element = event.element else { return }
                if let status = element {
                    strongSelf.configurePostloadData(status)
                }
            },
            viewModel.priority.subscribe { [weak self] event in
                guard let strongSelf = self, let priorityArray = event.element else { return }
                strongSelf.setupPriorityCircles(priorityArr: priorityArray)
                if (priorityArray.count == 0 ) { return }
                if priorityArray.count == 1 {
                    if priorityArray.first?.text == "P" {
                        strongSelf.hadTakeoverType = .none
                        strongSelf.ownPriorityLabel.setText(Constant.ownPriorityText)
                        if strongSelf.hasPriority == false {
                            var repeatCount = 0
                            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                                repeatCount += 1
                                WKInterfaceDevice.current().play(.failure)
                                if repeatCount == 3 {
                                    timer.invalidate()
                                }
                            }
                            strongSelf.hasPriority = true
                        }
                    } else if priorityArray.first?.text == "DQ" {
                        strongSelf.hasPriority = false
                        strongSelf.ownPriorityLabel.setText(Constant.disqualifiedText)
                    }
                    
                    strongSelf.ownPriorityView.setHidden(false)
                    strongSelf.priorityView.setHidden(true)
                } else {
                    if !strongSelf.statsViewModel.isInterference(priorityArray) {
                        strongSelf.hadTakeoverType = .none
                    }
                    strongSelf.ownPriorityView.setHidden(true)
                    strongSelf.priorityView.setHidden(false)
                    strongSelf.setupPriorityCircles(priorityArr: priorityArray)

                }
            },
            viewModel.totalScoreValue.subscribe { [weak self] event in
                guard let strongSelf = self, let scoreFloat = event.element else { return }
                strongSelf.scoreLabel.setText(String(format: "%.2f", scoreFloat))
            },
            viewModel.topScoresValue.subscribe { [weak self] event in
                guard let strongSelf = self, let scoreFloatArray = event.element else { return }
                strongSelf.top2ScoresLabel.setText(scoreFloatArray.map { String(format: "%.2f", $0) }.joined(separator: " + "))
            },
            viewModel.isOfflineMode.subscribe { [weak self] event in
                guard let strongSelf = self, let isOffline = event.element else { return }
                strongSelf.networkStatusUIMode(isOffline)
            },
            viewModel.takeoverMode.subscribe { [weak self] event in
                guard let strongSelf = self, let takeoverMode = event.element else { return }
                if takeoverMode != .none, let event = strongSelf.event, let athlete = strongSelf.athlete, strongSelf.hadTakeoverType != takeoverMode {
                        DispatchQueue.main.async {
                            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("StatsTakeover", StatsTakeOverStatus(takeoverType: takeoverMode, event: event, athlete: athlete) as AnyObject)])
                        }
                }
            },
            viewModel.heatPriority.subscribe { [weak self] event in
                guard let strongSelf = self, let heatPriority = event.element else { return }
                strongSelf.heatPulsingView.setHidden(!heatPriority)
            }
        )
        
        viewModel.loadModel(event: event, athlete: athlete)
        
    }
            
    private func startWorkoutIfNotStarted() {        
        //If workout is already started, bail immediately
        if (self.workoutInProgress) {
            return
        }
        
        let healthStore = HKHealthStore()
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .surfingSports
        workoutConfiguration.locationType = .outdoor
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration:  workoutConfiguration)
            session.delegate = self
            session.startActivity(with: Date())
            self.workoutSession = session
            self.workoutInProgress.toggle()
        } catch {
            let okAction = WKAlertAction(title: "OK", style: .default, handler:{})
            self.presentAlert(withTitle: "Error", message: "There was a problem starting the session.", preferredStyle: .alert, actions:   [okAction])
        }
    }
    
    private func stopWorkout() {
        if let session = self.workoutSession {
            session.end()
            self.workoutInProgress.toggle()
        }
    }
    
    private func configurePreloadData() {
        DDLogWarn("configurePreloadData")
        //Make sure loading label is visible
        self.loadingGroup.setHidden(false)
        self.loadingLabel.setText("Loading...")
        //Hide entire main UI until data is present
        self.fullGroup.setHidden(true)
        //Start the workout if not already started
        self.startWorkoutIfNotStarted()
    }
    
    private func configurePostloadData(_ status: String) {
        DDLogWarn("configurePostloadData with status \(status)")
        //Always show the scoring / timing after first successful load of data
        self.loadingGroup.setHidden(true)
        self.fullGroup.setHidden(false)
        
        if (status == "paused" || status == "upcoming") {
            if (!self.alertViewDisplayed) {
                let cancelAction = WKAlertAction(title: (status == "paused") ? "" : "CANCEL",
                                                 style: .cancel,
                                                 handler:{
                                                    self.alertViewDisplayed = false
                                                    self.dismissActiveCompanionView()
                })
                self.presentAlert(withTitle: "",
                                  message: (status == "paused") ? "HEAT IS PAUSED. CHECK BEACH ANNOUNCER FOR DIRECTIONS." :
                                    "HEAT HAS NOT STARTED. CHECK BEACH ANNOUNCER FOR DIRECTIONS.",
                                  preferredStyle: .actionSheet,
                                  actions: [cancelAction])
                self.alertViewDisplayed = true
            }
        } else if (self.alertViewDisplayed) {
            //Event is no longer paused or upcoming, so remove the modal
            self.dismiss()
        }
                            
    }
    
    private func handleEndUnixTimeStampUpdate(_ endUnixTimeStamp: TimeInterval) {
        let currentTimestamp = floor(Date().timeIntervalSince1970)
        
        //If the event happened in the past, bail quickly
        if (endUnixTimeStamp <= currentTimestamp) { return }
        
        //If the event end time extends out later (perhaps due to a pause), then proceed with updating countdown timer.
        if (endUnixTimeStamp <= self.savedUnixTimeStamp) { return }
        self.savedUnixTimeStamp = endUnixTimeStamp;
        
        //Start the countdown timer
        self.configureCountdownTimer(self.savedUnixTimeStamp)
        
    }
    
    private func configureCountdownTimer(_ endUnixTimeStamp: TimeInterval) {
        let countdownDate = Date.init(timeIntervalSince1970: endUnixTimeStamp)
        DDLogWarn("Configuring Countdowntimer with Date: \(countdownDate)")
        self.countdownTimer.setDate(countdownDate)
        self.countdownTimer.start()
    }
    
    private func dismissAndReturnToRoot() {
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("Tour",() as AnyObject), ("EnvConfig", () as AnyObject)])
    }
    
    private func setupPriorityCircles(priorityArr: [Priority]) {
        guard !priorityGroups.isEmpty else { return }
        for i in 0..<4 {
            let group = self.priorityGroups[i]
            if i < priorityArr.count {
                group.setHidden(false)
                self.priorityLabels[i].setVerticalAlignment(.center)
                
                let isWarning = priorityArr[i].text == "INT"
                let text = isWarning ? "⚠" : priorityArr[i].text ?? ""
                var prioritySize = Constant.prioritySmallCircleSize
                
                if self.statsViewModel.isMyNumber(numStr: priorityArr[i].athleteId) {
                    prioritySize = Constant.priorityBigCircleSize
                    if isWarning { self.priorityLabels[i].setVerticalAlignment(.top) }
                    let textSize = isWarning ? Constant.priorityInterruptFontSizeBig : Constant.priorityBigFontSize
                    let priorityFont = isWarning ? UIFont.systemFont(ofSize: textSize) : UIFont.boldSystemFont(ofSize: textSize)
                    let attrStr = NSAttributedString(string: text, attributes:
                                                        [.font: priorityFont])
                    self.priorityLabels[i].setAttributedText(attrStr)
                    
                } else {
                    var textSize = Constant.prioritySmallFontSize
                    if isWarning {
                        self.priorityLabels[i].setVerticalAlignment(.top)
                        textSize = Constant.priorityInterruptFontSizeSmall
                    } else if priorityArr[i].text == "DQ" {
                        textSize = Constant.priorityDQSmallFontSize
                    }
                    let priorityFont = UIFont.boldSystemFont(ofSize: CGFloat(textSize))
                    let attrStr = NSAttributedString(string: text, attributes:
                                                        [.font: priorityFont])
                    self.priorityLabels[i].setAttributedText(attrStr)
                }
                group.setWidth(prioritySize)
                group.setHeight(prioritySize)
                group.setCornerRadius(prioritySize / 2.0)
                
                let singlet = priorityArr[i].singlet
                if singlet == .Black {
                    group.setBackgroundColor(UIColor.white)
                    self.boarderViews[i].setBackgroundColor(singlet.getColor())
                    self.boarderViews[i].setCornerRadius(prioritySize * 0.85 / 2.0)
                } else {
                    group.setBackgroundColor(singlet.getColor())
                    self.boarderViews[i].setBackgroundColor(singlet.getColor())
                }
                
                switch singlet {
                    case .White:
                        self.priorityLabels[i].setTextColor(UIColor.init(named: "SingletBlack"))
                    case .Pink:
                        self.priorityLabels[i].setTextColor(UIColor.init(named: "SingletBlack"))
                    case .Yellow:
                        self.priorityLabels[i].setTextColor(UIColor.init(named: "SingletBlack"))
                    default:
                        self.priorityLabels[i].setTextColor(UIColor.init(named: "SingletWhite"))
                }
            } else {
                group.setHidden(true)
            }
        }
    }
    
    private func networkStatusUIMode(_ isOffline: Bool) {
        if isOffline {
            priorityView.setHidden(true)
            ownPriorityView.setHidden(true)
            offlineWaveView.setHidden(false)
            offlineWaveImage.startAnimatingWithImages(in: NSRange(location: 0, length: 31), duration: 2.3, repeatCount: 0)
            self.countdownTimer.setTextColor(UIColor.gray)
            self.scoreLabel.setTextColor(UIColor.gray)
            self.heatScoreTitle.setTextColor(UIColor.gray)
            self.needsDetailLabel.setTextColor(UIColor.gray)
            self.needsScoreLabel.setTextColor(UIColor.gray)
            self.top2ScoresLabel.setTextColor(UIColor.gray)
        } else {
            offlineWaveImage.stopAnimating()
            offlineWaveView.setHidden(true)
            priorityView.setHidden(hasPriority)
            ownPriorityView.setHidden(hasPriority)
            self.countdownTimer.setTextColor(UIColor.white)
            self.scoreLabel.setTextColor(UIColor.white)
            self.heatScoreTitle.setTextColor(UIColor.white)
            self.needsDetailLabel.setTextColor(UIColor.white)
            self.needsScoreLabel.setTextColor(UIColor.white)
            self.top2ScoresLabel.setTextColor(UIColor(named: "singletBlue"))
        }
    }
        
    // MARK: - HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if ((toState == .running) && (fromState == .notStarted)) {
            DispatchQueue.main.async {
                WKExtension.shared().enableWaterLock()                
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        DDLogWarn("Workout Event \(event)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DDLogWarn("Workout Session Failed with Error \(error)")
        DispatchQueue.main.async {
            let okAction = WKAlertAction(title: "OK", style: .default, handler:{})
            self.presentAlert(withTitle: "Error", message: "Session failed", preferredStyle: .alert, actions:   [okAction])
        }
    }

}
