//
//  StatsTakeOverStatus.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Derek W on 1/29/21.
//  Copyright © 2021 World Surf League. All rights reserved.
//

import Foundation

enum TakeoverType {
    case interference
    case disqualified
    case none
}

struct StatsTakeOverStatus {
    let takeoverType: TakeoverType
    let event: Event?
    let athlete: Athlete?
}
