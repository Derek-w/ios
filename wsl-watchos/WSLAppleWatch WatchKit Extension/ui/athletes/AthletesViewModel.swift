//
//  AthletesViewModel.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/14/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CocoaLumberjack

class AthletesViewModel {
    private var wslApiService: WSLApiService
    private var disposeBag = DisposeBag()
    private var event: Event?
    
    var athletes = BehaviorRelay<[Athlete]>(value: [])
    var error = PublishRelay<Bool>()
    
    init() {
        self.wslApiService = SwinjectUtil.sharedInstance.container.resolve(WSLApiService.self)!        
    }
    
    init(wslApiService: WSLApiService) {
        self.wslApiService = wslApiService        
    }
    
    func loadModel(_ event: Event) {
        self.event = event
        athletes.accept([])
        wslApiService.getEventAthletes(event.eventId).subscribe { [weak self] event in
            guard let strongSelf = self else { return }
            if let apiError = event.error {
                DDLogError("getEventAthletes api error: \(apiError.localizedDescription)")
                strongSelf.error.accept(true)
            } else if let result = event.element {
                strongSelf.athletes.accept(result)
            }
        }.disposed(by: disposeBag)
    }
    
    func getAthleteAtIndex(_ rowIndex: Int) -> Athlete? {
        guard rowIndex < athletes.value.count else { return nil }
        return athletes.value[rowIndex]
    }
    
}
