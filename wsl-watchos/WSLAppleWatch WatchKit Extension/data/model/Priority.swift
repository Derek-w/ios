//
//  Priority.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Onica on 1/28/20.
//  Copyright © 2020 World Surf League. All rights reserved.
//

import Foundation
import Himotoki

struct Priority: Himotoki.Decodable {
    
    let athleteId: String?
    let singlet: Singlet
    let text: String?
   
    static func decode(_ e: Extractor) throws -> Priority {
        let singletVal: String = try e <| "singlet"
        let singletEnum: Singlet = Singlet(rawValue: singletVal)!
        return Priority(athleteId: try e <|? "athleteId", singlet: singletEnum,
                       text: try e <|? "text")
                       
    }
    
    static func decodePriorities(_ array: [String]) -> [Priority] {
        var priorityArr = [Priority]()
        for json in array {
            if let athlete = (try? Priority.decodeValue(json) as Priority?) {
                priorityArr.append(athlete)
            }
        }
        
        return priorityArr;
    }
}
