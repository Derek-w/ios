//
//  OAuthToken.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by Scott Wang on 10/9/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import Himotoki

struct OAuthToken: Himotoki.Decodable {
    let accessToken: String
    let tokenType: String
    let expires: Int
    
    static func decode(_ e: Extractor) throws -> OAuthToken {
        return OAuthToken(accessToken: try e <| "access_token",
                          tokenType: try e <| "token_type",
                          expires: try e <| "expires_in")
    }
}
