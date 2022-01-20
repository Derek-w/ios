//
//  EventsViewModel.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/15/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CocoaLumberjack

class EventsViewModel {
    private var wslApiService: WSLApiService
    private var disposeBag = DisposeBag()
    private var tour: Tour?
    
    var events = BehaviorRelay<[Event]>(value: [])
    var error = PublishRelay<String>()
    
    init() {
        self.wslApiService = SwinjectUtil.sharedInstance.container.resolve(WSLApiService.self)!
    }
    
    init(wslApiService: WSLApiService) {
        self.wslApiService = wslApiService
    }
    
    func loadModel(_ tour: Tour) {
        self.tour = tour
        events.accept([])
        
       
        wslApiService.getEvents(tour.tourId).subscribe { [weak self] event in
            guard let strongSelf = self else { return }
            if let apiError = event.error {
                DDLogError("getEvents api error: \(apiError.localizedDescription)")
                strongSelf.error.accept(apiError.localizedDescription)
            } else if let result = event.element {
                strongSelf.events.accept(result)
            }
        }.disposed(by: disposeBag)
    }
    
    func getEventAtIndex(_ rowIndex: Int) -> Event? {
        guard rowIndex < events.value.count else { return nil }
        return events.value[rowIndex]
    }
}
