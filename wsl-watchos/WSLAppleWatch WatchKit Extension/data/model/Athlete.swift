//
//  Athlete.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/14/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import Himotoki

struct Athlete: Himotoki.Decodable {
    
    let athleteId: String
    let firstName: String?
    let lastName: String?
    let headshotImageUrl: String?
    var isActive: Bool = false
    var heatNumber: Int = 0
    var roundId: String?
    
    var displayName: String {
        var firstLetter = firstName?.prefix(1) ?? ""
        if firstLetter.count > 0 {
            firstLetter.append(contentsOf: ". ")
        }
        
        return "\(firstLetter)\(lastName ?? "")"
    }
    
    static func decode(_ e: Extractor) throws -> Athlete {
        return Athlete(athleteId: try e <| "athleteId",
                       firstName: try e <|? "firstName",
                       lastName: try e <|? "lastName",
                       headshotImageUrl: try e <|? "headshotImageUrl")
    }
    
    static func decodeAthletes(_ dictionary: [String: Any]) -> [Athlete] {
        var athleteArr = [Athlete]()
        for (_, athleteJson) in dictionary {
            if let athlete = (try? Athlete.decodeValue(athleteJson) as Athlete?) {
                athleteArr.append(athlete)
            }
        }
        
        return athleteArr
    }
}
