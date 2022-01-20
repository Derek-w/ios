
import Foundation
import Alamofire
import CocoaLumberjack

class OAuth2Handler: RequestAdapter, RequestRetrier {
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?) -> Void
    
    private let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        
        return SessionManager(configuration: configuration)
    }()
    
    private let lock = NSLock()
    
    private var clientID: String
    private var baseURLString: String
    private var pushApiBaseString: String
    private var baseOAuthURLString: String
    private var clientToken: String
    private var clientSecret: String
    
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    private let maxRetries = 2
    // MARK: - Initialization
    
    public init() {
        self.clientID = App.sharedInstance.appEnvironment.apiClientKey
        self.baseURLString = App.sharedInstance.appEnvironment.apiBaseUrl
        self.pushApiBaseString = App.sharedInstance.appEnvironment.pushApiBaseUrl
        self.baseOAuthURLString = App.sharedInstance.appEnvironment.apiBaseUrl
        self.clientToken = "x.y.z"
        self.clientSecret = App.sharedInstance.appEnvironment.apiClientSecret
    }
    
    func refreshEnvSettings() {
        self.clientID = App.sharedInstance.appEnvironment.apiClientKey
        self.baseURLString = App.sharedInstance.appEnvironment.apiBaseUrl
        self.pushApiBaseString = App.sharedInstance.appEnvironment.pushApiBaseUrl
        self.baseOAuthURLString = App.sharedInstance.appEnvironment.apiBaseUrl
        self.clientSecret = App.sharedInstance.appEnvironment.apiClientSecret
    }
    
    // MARK: - RequestAdapter
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix(baseURLString) || urlString.hasPrefix(pushApiBaseString) {
            var urlRequest = urlRequest
            urlRequest.setValue("Bearer " + clientToken, forHTTPHeaderField: "Authorization")
            return urlRequest
        }
        
        return urlRequest
    }
    
    // MARK: - RequestRetrier
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 400, let urlString = request.request?.url?.absoluteString {
            
            if request.retryCount > maxRetries {
                completion(false, 0.0)
                
            } else {
                requestsToRetry.append(completion)

                let tokenType = "client_credentials"

                if !isRefreshing {
                    refreshTokens(tokenType: tokenType) { [weak self] succeeded, accessToken in
                        guard let strongSelf = self else { return }
                        
                        strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                        
                        if let accessToken = accessToken {
                            strongSelf.clientToken = accessToken
                        }
                        
                        strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
                        strongSelf.requestsToRetry.removeAll()
                    }
                }
            }
        } else {
            completion(false, 0.0)
        }
    }
    
    // MARK: - Private - Refresh Tokens
    
    private func refreshTokens(tokenType: String, completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        let args = ["grant_type" : tokenType,
                    "client_id" : self.clientID,
                    "client_secret" : self.clientSecret ]
        
        let url = baseOAuthURLString + "/v1/oauth/token"
        DDLogDebug("POST Api: \(url)")
        
        let queue = DispatchQueue(label: "WorldSurfLeague.Network.Queue", attributes: .concurrent)
        let request = Alamofire.request(url, method: .post, parameters: args, encoding: URLEncoding.default, headers: nil).responseJSON(queue: queue) { [weak self] response in
            guard let strongSelf = self else { return }
            
            if response.result.isSuccess {
                if let value = response.result.value, let token = (try? OAuthToken.decodeValue(value)) as OAuthToken? {
                    completion(true, token.accessToken)
                } else {
                    completion(false, nil)
                }
            } else if response.result.isFailure {
                DDLogError(String(describing: response.result.error))
                completion(false, nil)
            }
            strongSelf.isRefreshing = false
        }
        DDLogDebug(request.debugDescription)
    }
}
