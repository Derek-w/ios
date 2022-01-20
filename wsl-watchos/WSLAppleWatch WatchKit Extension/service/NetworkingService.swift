
import Foundation

import RxSwift
import Alamofire

protocol NetworkingService {
    func getRequestJSON(url: String, parameters: [String : AnyObject]?, headers:[String: String]?)
        -> Observable<DataResponse<Any>>
    func postRequestJSON(url: String, parameters: [String : AnyObject]?, headers:[String: String]?)
        -> Observable<DataResponse<Any>>
    func postRequestJSONWithEmptyResponse(url: String, parameters: [String : AnyObject]?, headers:[String: String]?)
    -> Observable<(HTTPURLResponse, String)>
    func patchRequestJSON(url: String, parameters: [String : AnyObject]?, headers:[String: String]?)
        -> Observable<DataResponse<Any>>
    func deleteRequestJSON(url: String, parameters: [String : AnyObject]?, headers:[String: String]?)
        -> Observable<DataResponse<Any>>
}

