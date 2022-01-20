//
//  EnvConfigInterfaceController.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Chris O'Malley on 12/8/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import WatchKit
import CoreLocation
import HealthKit
import CocoaLumberjack

class EnvConfigInterfaceController: RxInterfaceController {
    private var EnvConfigViewModel: EnvConfigViewModel!
    private let logFileService = LogFileService()
    
    @IBOutlet weak var uploadLogsButton: WKInterfaceButton!
    
    @IBOutlet weak var prodButton: WKInterfaceButton!
    @IBOutlet weak var stageButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        configureButtons()
    }
        
    @IBAction func prodPressed() {
        setEnvironment(false)
    }
    
    @IBAction func stagePressed() {
        setEnvironment(true)
    }
    
    @IBAction func sendLogFilesPressed() {
        sendLogFiles()
    }
    
    private func setEnvironment(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Constant.USE_STAGE_ENV_KEY)
        configureButtons();
        showEnvironmentChangeAlert();
    }
    
    private func configureButtons() {
        let wslBlue = UIColor.init(named: "SingletBlue")
        if (UserDefaults.standard.bool(forKey: Constant.USE_STAGE_ENV_KEY)) {
            self.prodButton.setBackgroundColor(nil)
            self.stageButton.setBackgroundColor(wslBlue)
        } else {
            self.prodButton.setBackgroundColor(wslBlue)
            self.stageButton.setBackgroundColor(nil)
        }
    }
    
    private func showEnvironmentChangeAlert() {
        let okAction = WKAlertAction(title: "OK", style: .default, handler:{})
        self.presentAlert(withTitle: "Heads up!", message: "For the new environment setting to take effect, please force quit the application.", preferredStyle: .alert, actions:   [okAction])
    }
        
    private func sendLogFiles() {
        DDLogInfo("Upload start")
        self.uploadLogsButton.setEnabled(false)
        self.uploadLogsButton.setTitle("Uploading...")
        _ = self.logFileService.processExistingLogFiles().subscribe { event in
            if event.isStopEvent {
                DDLogInfo("Upload completed")
                self.uploadLogsButton.setEnabled(true)
                self.uploadLogsButton.setTitle("Upload")
            }
        }.disposed(by: disposeBag)
    }
        
   
}
