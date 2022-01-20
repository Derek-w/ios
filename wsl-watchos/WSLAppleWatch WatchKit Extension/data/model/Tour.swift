//
//  Tour.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/12/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import Himotoki

struct Tour: Himotoki.Decodable {

    let tourId: String
    let name: String
    let code: String
    
    static func decode(_ e: Extractor) throws -> Tour {
        return Tour(tourId: try e <| "tourId",
                    name: try e <| "name",
                    code: try e <| "code")
    }
    
    static func decodeTours(_ dictionary: [String: Any]) -> [Tour] {
        var tourArr = [Tour]()
        for (_, tourJson) in dictionary {
            if let tour = (try? Tour.decodeValue(tourJson)) as Tour? {
                tourArr.append(tour)
            }
        }
        
        // Sorted by id
        return tourArr.sorted { (t1, t2) -> Bool in
            guard let id1 = Int(t1.tourId), let id2 = Int(t2.tourId) else { return false }
            return id1 < id2
        }
    }
}
