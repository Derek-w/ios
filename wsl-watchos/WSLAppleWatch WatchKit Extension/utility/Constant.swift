

import Foundation
import RxSwift
import WatchKit

class Constant {
    
    static let STAT_POLL_INTERVAL: TimeInterval = 1
    static let PUSH_TOKEN_KEY: String = "pushToken"
    static let EVENT_STATUS_UPDATE_KEY: String = "EventStatusUpdate"
    static let USE_STAGE_ENV_KEY: String = "useStageEnv"
    static let COMPANION_SESSION_ENDED_KEY: String = "SessionEnded"
    
    static let ownPriorityText: String = "PRIORITY"
    static let disqualifiedText: String = "DQ"
    static let disqualifiedWarningText: String = "YOU ARE DISQUALIFIED"
    static let interferenceWarningText: String = "INTERFERENCE"
    
    static let MAX_NETWORK_FAILURE_ALLOWED: Int = 5
    static let isBiggerScreen = WKInterfaceDevice.current().screenBounds.width > CGFloat(162.0)
    
    // Relative to full group view height
    static let prioritySmallCircleSize = CGFloat(Int((isBiggerScreen ? 184 : 164) * 0.48 * 0.32))
    static let priorityBigCircleSize = CGFloat(Int((isBiggerScreen ? 176 : 164) * 0.48 * 0.58))
    static let priorityInterruptFontSizeSmall = CGFloat(isBiggerScreen ? 19 : 17)
    static let priorityInterruptFontSizeBig = CGFloat(isBiggerScreen ? 33 : 30)
    static let priorityBigFontSize = CGFloat(isBiggerScreen ? 26 : 24)
    static let prioritySmallFontSize = CGFloat(isBiggerScreen ? 18 : 17)
    static let priorityDQSmallFontSize = CGFloat(isBiggerScreen ? 15 : 13)
}
