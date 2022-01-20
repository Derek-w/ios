//
//  App.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/9/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation

class App {
    
    static let sharedInstance = App()
    
    var appEnvironment : AppEnvironment
    var tours = [Tour]()
    var events = [Event]()
    var heats = [Heat]()
    var athletes = [Athlete]()
    
    fileprivate init() {
        let stage = (UserDefaults.standard.bool(forKey: Constant.USE_STAGE_ENV_KEY))
        appEnvironment = AppEnvironment.init(withEnvironmentId: stage ? "Stage" : "Production")
    }
    
    func setTours(_ tours: [Tour]) {
        self.tours = tours
    }
    
}
