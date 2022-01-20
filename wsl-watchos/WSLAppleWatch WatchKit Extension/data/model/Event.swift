//
//  Event.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/15/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import Himotoki

struct Event: Himotoki.Decodable {
    
    let eventId: String
    let name: String
    let currentHeatIds: [String]
    let isActive: Bool
    
    static func decode(_ e: Extractor) throws -> Event {
        return Event(eventId: try e <| "eventId",
                     name: try e <| "name",
                     currentHeatIds: try e <| "currentHeatIds",
                     isActive: try e <| "isActive")
    }
    
    static func decodeEvents(_ dictionary: [String: Any]) -> [Event] {
        var eventArr = [Event]()
        for (_, eventJson) in dictionary {
            if let event = (try? Event.decodeValue(eventJson)) as Event? {
                eventArr.append(event)
            }
        }
        
        // Sorted by id
        return eventArr.sorted { (e1, e2) -> Bool in
            guard let id1 = Int(e1.eventId), let id2 = Int(e2.eventId) else { return false }
            return id1 < id2
        }
    }
    
    static func decodeEvent(_ dictionary: [String: Any], eventId: String) -> Event? {
        let events = Event.decodeEvents(dictionary)
        for event in events {
            if event.eventId == eventId {
                return event
            }
        }
        return nil
    }
}
