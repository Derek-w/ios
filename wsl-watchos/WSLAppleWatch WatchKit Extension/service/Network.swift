import Foundation

import RxSwift
import RxAlamofire
import CocoaLumberjack
import Alamofire

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
        debugPrint(self)
        #endif
        return self
    }
}

final class Network : NetworkingService {
    private let queue = DispatchQueue(label: "WorldSurfLeague.Network.Queue")
    
    var alamoFireManager : Alamofire.SessionManager
    var oAuth2Handler = OAuth2Handler()
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5 // seconds
        configuration.timeoutIntervalForResource = 5
        self.alamoFireManager = Alamofire.SessionManager(configuration: configuration)
        self.alamoFireManager.adapter = oAuth2Handler
        self.alamoFireManager.retrier = oAuth2Handler
    }
    
    func getRequestJSON(url: String, parameters: [String : AnyObject]?, headers: [String: String]?)
        -> Observable<DataResponse<Any>>
    {
        DDLogDebug("GET URL: \(url)")
        if let parameters = parameters {
            DDLogDebug("Parameters: \(parameters)")
        }
        
        #if DEBUG
        _ = Alamofire.request(url, method: .get, parameters: parameters, headers: headers).debugLog()
        #endif
        
        return alamoFireManager.rx.request(.get, url, parameters: parameters, headers: headers).validate().responseJSON()
        
    }
    
    func postRequestJSON(url: String, parameters: [String : AnyObject]?, headers: [String: String]?)
        -> Observable<DataResponse<Any>>
    {
        DDLogDebug("POST URL: \(url)")
        if let parameters = parameters {
            DDLogDebug("Parameters: \(parameters)")
        }
        
        
        #if DEBUG
        _ = Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
        #endif
        
        return alamoFireManager.rx.request(.post, url, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseJSON()
    }
    
    func postRequestJSONWithEmptyResponse(url: String, parameters: [String : AnyObject]?, headers: [String: String]?)
        -> Observable<(HTTPURLResponse, String)>
    {
        DDLogDebug("POST URL: \(url)")
        if let parameters = parameters {
            DDLogDebug("Parameters: \(parameters)")
        }
        
        
        #if DEBUG
        _ = Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).debugLog()
        #endif
        
        return alamoFireManager.rx.request(.post, url, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseString()
    }
    
    func patchRequestJSON(url: String, parameters: [String : AnyObject]?, headers: [String: String]?)
        -> Observable<DataResponse<Any>>
    {
        DDLogDebug("PATCH URL: \(url)")
        if let parameters = parameters {
            DDLogDebug("Parameters: \(parameters)")
        }
        
        
        #if DEBUG
        _ = Alamofire.request(url, method: .patch, parameters: parameters, headers: headers).debugLog()
        #endif
        
        return alamoFireManager.rx.request(.patch, url, parameters: parameters, headers: headers).validate().responseJSON()
    }
    
    func deleteRequestJSON(url: String, parameters: [String : AnyObject]?, headers: [String: String]?)
        -> Observable<DataResponse<Any>>
    {
        DDLogDebug("DELETE URL: \(url)")
        if let parameters = parameters {
            DDLogDebug("Parameters: \(parameters)")
        }
        
        
        #if DEBUG
        _ = Alamofire.request(url, method: .delete, parameters: parameters, headers: headers).debugLog()
        #endif
        
        return alamoFireManager.rx.request(.delete, url, parameters: parameters, headers: headers).validate().responseJSON()
    }
}
