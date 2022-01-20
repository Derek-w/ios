//
//  StatsAuxInterfaceController.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Chris O'Malley on 12/6/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import WatchKit
import CoreLocation
import HealthKit
import CocoaLumberjack

class StatsAuxInterfaceController: RxInterfaceController {
    private var statsAuxViewModel: StatsAuxViewModel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        guard let (_, athlete) = context as? (Event, Athlete) else { return }
        setTitle("\(athlete.displayName)")
    }
   
    @IBAction func exitPressed() {
        NotificationCenter.default.post(name: Notification.Name(Constant.COMPANION_SESSION_ENDED_KEY), object: self, userInfo: nil)     
    }
}
