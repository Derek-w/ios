
import Foundation
import Himotoki

struct Round: Himotoki.Decodable {
    let roundId: String
    let eventId: String
    let roundNumber: Int
    let name: String?
    let shortName: String?
    let abbr: String?
    
    static func decode(_ e: Extractor) throws -> Round {
        return Round(roundId: try e <| "roundId",
                     eventId: try e <| "eventId",
                     roundNumber: try e <| "roundNumber",
                     name: try e <|? "name",
                     shortName: try e <|? "shortName",
                     abbr: try e <|? "abbr")
    }
    
    static func decodeRounds(_ dictionary: [String: Any]) -> [Round] {
        var roundArr = [Round]()
        for (_, roundJson) in dictionary {
            if let round = (try? Round.decodeValue(roundJson)) as Round? {
                roundArr.append(round)
            }
        }
        return roundArr
    }
    
    static func decodeRound(_ dictionary: [String: Any], roundId: String) -> Round? {
        let roundArr = Round.decodeRounds(dictionary)
        for round in roundArr {
            if round.roundId == roundId {
                return round
            }
        }
        return nil
    }
}
