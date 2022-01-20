//
//  ToursViewModel.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/14/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CocoaLumberjack
import WatchKit

class ToursViewModel {
    private var wslApiService: WSLApiService
    private var disposeBag = DisposeBag()
    private var wslPushService: WSLPushService
    
    var tours = BehaviorRelay<[Tour]>(value: [])
    var error = PublishRelay<Bool>()
    
    init() {
        self.wslApiService = SwinjectUtil.sharedInstance.container.resolve(WSLApiService.self)!
        self.wslPushService = SwinjectUtil.sharedInstance.container.resolve(WSLPushService.self)!
    }
    
    init(wslApiService: WSLApiService, wslPushService: WSLPushService) {
        self.wslApiService = wslApiService
        self.wslPushService = wslPushService
    }
    
    func loadModel() {
        tours.accept([])
        wslApiService.getTours().subscribe { [weak self] event in
            guard let strongSelf = self else { return }
            if let apiError = event.error {
                DDLogError("getTours api error: \(apiError.localizedDescription)")
                strongSelf.error.accept(true)
            } else if let result = event.element {
                strongSelf.tours.accept(result)
            }
        }.disposed(by: disposeBag)
    }
    
    func getTourAtindex(_ rowIndex: Int) -> Tour? {
        guard rowIndex < tours.value.count else { return nil }

        return tours.value[rowIndex]
    }
    
}
