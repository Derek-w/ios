//
//  Event.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/15/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import Himotoki

struct EventStatus: Himotoki.Decodable {
    
    let athleteId: String
    let targetScoreValue: String
    let targetScoreLabel: String
    let priority: [Priority]
    let totalScoreValue: Double
    let topScoresValue: [Double]
    let status: String?
    let endUnixTimeStamp: Double?
    let heatPriority: Bool?
    
    static func decode(_ e: Extractor) throws -> EventStatus {
        
        let priorityArr: [Priority] = try e <| "priority"
        
        return EventStatus(athleteId: try e <| "athleteId",
                     targetScoreValue: try e <| "targetScoreValue",
                     targetScoreLabel: try e <| "targetScoreLabel",
                     priority: priorityArr,
                     totalScoreValue: try e <| "totalScoreValue",
                     topScoresValue: try e <| "topScoresValue",
                     status: try e <|? "status",
                     endUnixTimeStamp: try e <|? "endUnixTimeStamp",
                     heatPriority: try e <|? "heatPriority")
    }
    
    static func decodeEventStatus(_ eventString: String) -> EventStatus? {
        let convertJson = eventString.convertToDictionary()
        guard let eventJson = convertJson else { return nil }
        return EventStatus.decodeEventStatus(eventJson)
    }
    
    static func decodeEventStatus(_ eventJson: [String: Any]) -> EventStatus? {
        if let eventStatus = (try? EventStatus.decodeValue(eventJson)) as EventStatus? {
            return eventStatus;
        } else {
            return nil;
        }
    }
    
}
