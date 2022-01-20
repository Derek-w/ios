//
//  HeatAthlete.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/16/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import Himotoki

struct HeatAthlete: Himotoki.Decodable {
    
    let athleteId: String
    let place: Int?
    let score: Double?
    let singlet: Singlet?
    let interference: Bool
    let interferenceType: String?
    let needsText: String?
    let needsLabel: String?
    let needsValue: String?
    let toAdvanceLabel: String?
    let toAdvance: String?
    let status: String?
    
    static func decode(_ e: Extractor) throws -> HeatAthlete {
        let interferenceVal: Bool? = try e <|? "interference"
        let singletVal: String? = try e <|? "singlet"
        let singletEnum: Singlet? = (singletVal != nil ? Singlet(rawValue: singletVal!) : nil)
        
        return HeatAthlete(athleteId: try e <| "athleteId",
                           place: try e <|? "place",
                           score: try e <|? "score",
                           singlet: singletEnum,
                           interference: interferenceVal ?? false,
                           interferenceType: try e <|? "interferenceType",
                           needsText: try e <|? "needsText",
                           needsLabel: try e <|? "needsLabel",
                           needsValue: try e <|? "needsValue",
                           toAdvanceLabel: try e <|? "toAdvanceLabel",
                           toAdvance: try e <|? "toAdvance",
                           status: try e <|? "status")
    }
}
