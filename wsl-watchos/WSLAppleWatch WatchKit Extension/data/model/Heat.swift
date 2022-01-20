//
//  Heat.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/16/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import Himotoki
import UIKit

enum Singlet: String {
    case White = "white"
    case Red = "red"
    case Black = "black"
    case Blue = "blue"
    case Pink = "pink"
    case Yellow = "yellow"
    case Orange = "orange"
    case Purple = "purple"
    case Green = "green"
    
    func getColor() -> UIColor {
        switch self {
        case .White:
            return UIColor.init(named: "SingletWhite")!
        case .Red:
            return UIColor.init(named: "SingletRed")!
        case .Black:
            return UIColor.init(named: "SingletBlack")!
        case .Blue:
            return UIColor.init(named: "SingletBlue")!
        case .Pink:
            return UIColor.init(named: "SingletPink")!
        case .Yellow:
            return UIColor.init(named: "SingletYellow")!
        case .Orange:
            return UIColor.init(named: "SingletOrange")!
        case .Purple:
            return UIColor.init(named: "SingletPurple")!
        case .Green:
            return UIColor.init(named: "SingletGreen")!
        }
    }
}

struct Heat: Himotoki.Decodable {
    
    let heatId: String
    let eventId: String
    let roundId: String
    let heatNumber: Int
    let numAthletes: Int
    let timeRemaining: Int
    let isStarted: Bool
    let isOver: Bool
    let isActive: Bool
    let isLive: Bool
    let athleteIds: [String]
    let athletes: [String: HeatAthlete]

    static func decode(_ e: Extractor) throws -> Heat {
        return Heat(heatId: try e <| "heatId",
                    eventId: try e <| "eventId",
                    roundId: try e <| "roundId",
                    heatNumber: try e <| "heatNumber",
                    numAthletes: try e <| "numAthletes",
                    timeRemaining: try e <| "timeRemaining",
                    isStarted: try e <| "isStarted",
                    isOver: try e <| "isOver",
                    isActive: try e <| "isActive",
                    isLive: try e <| "isLive",
                    athleteIds: try e <| "athleteIds",
                    athletes: try e <| "athletes")
    }
    
    static func decodeHeats(_ dictionary: [String: Any]) -> [Heat] {
        var heatsArr = [Heat]()
        for (_, heatJson) in dictionary {
            if let heat = (try? Heat.decodeValue(heatJson)) as Heat? {
                heatsArr.append(heat)
            }
        }
        return heatsArr
    }
    
    // Return a heat that contains an athlete
    static func decodeHeatAthlete(_ dictionary: [String: Any], heatIds: [String], athleteId: String) -> Heat? {
        let heatsArr = Heat.decodeHeats(dictionary)
        for heat in heatsArr {
            if heatIds.contains(heat.heatId) {
                for (id, _) in heat.athletes {
                    if id == athleteId {
                        return heat
                    }
                }
            }
        }
        return nil
    }
    
    func getHeatAthlete(_ athleteId: String) -> HeatAthlete? {
        for (id, athlete) in athletes {
            if id == athleteId {
                return athlete
            }
        }
        return nil
    }
    
    func getHeatAhtletesInPlaceOrder() -> [HeatAthlete] {
        return Array(athletes.values).sorted { (heatAthlete1, heatAthlete2) -> Bool in
            guard let place1 = heatAthlete1.place, let place2 = heatAthlete2.place else { return false }
            return place1 < place2
        }
    }
}

