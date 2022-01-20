//
//  AppEnvironment.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/9/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import CocoaLumberjack

class AppEnvironment {
    
    enum ConfigurationEnvironment : String {
        case Production, DebugProduction, Stage
        static let allValues: [ConfigurationEnvironment] = [Production, Stage]
    }
    
    var configurationEnvironment : ConfigurationEnvironment?
    
    var apiBaseUrl : String = ""
    var pushApiBaseUrl : String = ""
    var pushWssBaseUrl : String = ""
    var apiClientKey: String = ""
    var apiClientSecret: String = ""
    
    init(withEnvironmentId environment: String = "Production") {
        configurationEnvironment = ConfigurationEnvironment.init(rawValue: environment)
        
        if let env = configurationEnvironment {
            DDLogInfo("ENVIRONMENT: \(env)")
            
            if let path = Bundle.main.path(forResource: "Environments", ofType: "plist"),
                let dict = NSDictionary(contentsOfFile: path) as? [String:AnyObject] {
                
                if let environmentConfig = dict[env.rawValue] as? [String: AnyObject] {
                    apiBaseUrl = environmentConfig["apiBaseUrl"] as! String
                    pushApiBaseUrl = environmentConfig["pushApiBaseUrl"] as! String
                    pushWssBaseUrl = environmentConfig["pushWssBaseUrl"] as! String
                }
            }
        
            apiClientKey = "wsl_watchos"
            switch env {
            case .Production:
                apiClientSecret = "ui6W9x,Z2.vJ9"
            case .DebugProduction:
                apiClientSecret = "ui6W9x,Z2.vJ9"
            case .Stage:
                apiClientSecret = "ui6W9x,Z2.vJ9"
            }
        }
    }
}
