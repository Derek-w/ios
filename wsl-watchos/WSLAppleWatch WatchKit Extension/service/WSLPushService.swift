//
//  WSLPushService.swift
//  WSLAppleWatch WatchKit Extension
//
//  Created by chris.o. on 11/20/19.
//  Copyright © 2019 World Surf League. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import CocoaLumberjack
import Alamofire

class WSLPushService {
    private static let ApiPathRegisterToken = "/v1/registerToken"
    private static let ApiPathGetEventStatus = "/v1/eventStatus"
    private static let ApiPathPostLogs = "/logs"
    
    fileprivate var network: NetworkingService

    init(network: NetworkingService) {
        self.network = network
    }

    func registerPushToken(_ token: String, athleteId: String, eventId: String) -> Observable<Bool> {
        let baseUrl = App.sharedInstance.appEnvironment.pushApiBaseUrl
        let path = baseUrl + WSLPushService.ApiPathRegisterToken
        let params = ["token": token as AnyObject, "athleteId" : athleteId as AnyObject, "eventId" : eventId as AnyObject]
        return Observable<Bool>.create { (observer) -> Disposable in
            self.network.postRequestJSON(url: path, parameters: params, headers: nil)
                .debug()
                .subscribe(onNext: { (response) in
                    observer.onNext(true)
                    observer.onCompleted()
                }, onError: { (error) in
                    DDLogError("On Error")
                    DDLogError(error.localizedDescription)
                    observer.onError(error)
                }, onCompleted: {
                    DDLogDebug("On Completed")
                    observer.onCompleted()
                }, onDisposed: {
                    DDLogDebug("On Disposed")
                })
        }
    }
    
    func getEventStatus(_ eventId: String, athleteId: String) -> Observable<EventStatus> {
         let baseUrl = App.sharedInstance.appEnvironment.pushApiBaseUrl
         let path = baseUrl + WSLPushService.ApiPathGetEventStatus
         let params = ["athleteId" : athleteId as AnyObject, "eventId" : eventId as AnyObject]
         return Observable<EventStatus>.create { (observer) -> Disposable in
             self.network.getRequestJSON(url: path, parameters: params, headers: nil)
                 .debug()
                 .subscribe(onNext: { (response) in
                     if let json = response.result.value as? [String: Any],
                        let eventStatus = EventStatus.decodeEventStatus(json) {
                         observer.onNext(eventStatus)
                         observer.onCompleted()
                     } else {
                         observer.onError(NSError(domain: "WSL", code: 0, userInfo:[NSLocalizedDescriptionKey:"Unexpected Events JSON"]))
                     }
                 }, onError: { (error) in
                     DDLogError("On Error")
                     DDLogError(error.localizedDescription)
                     observer.onError(error)
                 }, onCompleted: {
                     DDLogDebug("On Completed")
                     observer.onCompleted()
                 }, onDisposed: {
                     DDLogDebug("On Disposed")
                 })
         }
     }
    
    func uploadLogFiles(_ fileName: String, fileContents: String) -> Observable<Bool> {
        let baseUrl = App.sharedInstance.appEnvironment.pushApiBaseUrl
        let path = baseUrl + WSLPushService.ApiPathPostLogs + "/" + fileName
        let params = [fileName : fileContents as AnyObject]
        
        return Observable<Bool>.create { (observer) -> Disposable in
            self.network.postRequestJSONWithEmptyResponse(url: path, parameters: params, headers: nil)
                .debug()
                .subscribe(onNext: { (response) in
                    DDLogDebug("On Next")
                    observer.onNext(true)
                }, onError: { (error) in
                    DDLogError("On Error")
                    DDLogError(error.localizedDescription)
                    observer.onError(error)
                }, onCompleted: {
                    DDLogDebug("On Completed")
                    observer.onCompleted()
                }, onDisposed: {
                    DDLogDebug("On Disposed")
                })
        }
    }
        
}
