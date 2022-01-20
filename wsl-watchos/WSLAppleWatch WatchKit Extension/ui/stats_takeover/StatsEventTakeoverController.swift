//
//  StatsInterferenceController.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Derek W on 1/25/21.
//  Copyright © 2021 World Surf League. All rights reserved.
//

import WatchKit
import Foundation

class StatsEventTakeoverController: RxInterfaceController {
    
    @IBOutlet weak var warningView: WKInterfaceGroup!
    var takeoverMode: StatsTakeOverStatus?
    @IBOutlet weak var glyphLabel: WKInterfaceLabel!
    @IBOutlet weak var warningTitleLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        guard let takeoverStatus = context as? StatsTakeOverStatus else { return }
        takeoverMode = takeoverStatus
        self.setTitle(takeoverMode?.athlete?.displayName)
        self.animate()
    }
    
    private func animate() {
        switch takeoverMode?.takeoverType {
        case .disqualified:
            self.glyphLabel.setHidden(true)
            self.warningTitleLabel.setText(Constant.disqualifiedWarningText)
        default:
            self.glyphLabel.setHidden(false)
            self.warningTitleLabel.setText(Constant.interferenceWarningText)
        }
        var count = 0
        self.warningView.setAlpha(0)
        self.animate(withDuration: 3) {
            WKInterfaceDevice.current().play(.notification)
            self.warningView.setAlpha(1)
        }
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] timer in
            count += 1
            WKInterfaceDevice.current().play(.notification)
            self?.warningView.setAlpha(0)
            self?.animate(withDuration: 3) {
                self?.warningView.setAlpha(1)
            }
            if count == 3 {
                timer.invalidate()
                DispatchQueue.main.async {
                    WKInterfaceController.reloadRootControllers(withNamesAndContexts: [("Stats", (self?.takeoverMode?.event, self?.takeoverMode?.athlete, self?.takeoverMode?.takeoverType) as AnyObject), ("StatsAux", (self?.takeoverMode?.event, self?.takeoverMode?.athlete) as AnyObject)])
                }
            }
        }
    }
}
