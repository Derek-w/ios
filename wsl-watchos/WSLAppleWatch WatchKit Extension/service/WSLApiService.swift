

import Foundation
import RxCocoa
import RxSwift
import CocoaLumberjack
import Alamofire

class WSLApiService {
    private static let ApiPathTours = "/v1/site/tours"
    private static let ApiPathTourAthleteRankings = "/v1/tour/athleterankings"
    private static let ApiPathTourEvents = "/v1/tour/events"
    private static let ApiPathEventDetails = "/v1/event/details"
    private static let ApiPathEventStatus = "/v1/event/status"
    private static let ApiPathLogEventWatchUsage = "/v1/feeds/setapplewatchused"

    fileprivate var network: NetworkingService

    init(network: NetworkingService) {
        self.network = network
    }

    func getTours() -> Observable<[Tour]> {
        let baseUrl = App.sharedInstance.appEnvironment.apiBaseUrl
        let path = baseUrl + WSLApiService.ApiPathTours
        
        return Observable<[Tour]>.create { (observer) -> Disposable in
            self.network.getRequestJSON(url: path, parameters: self.appendCommonParameters([:]), headers: nil)
                .debug()
                .subscribe(onNext: { response in
                    if let json = response.result.value as? [String: Any], let toursJson = json["tours"] as? [String: Any] {
                        let tours = Tour.decodeTours(toursJson)
                        observer.onNext(tours)
                        observer.onCompleted()
                    } else {
                        observer.onError(NSError(domain: "WSL", code: 0, userInfo:[NSLocalizedDescriptionKey:"Unexpected Tours JSON"]))
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
    
    func getEvents(_ tourId: String, active: Bool = true) -> Observable<[Event]> {
        let baseUrl = App.sharedInstance.appEnvironment.apiBaseUrl
        let path = baseUrl + WSLApiService.ApiPathTourEvents
        let parameters = self.appendCommonParameters(["tourId" : tourId as AnyObject])

        return Observable<[Event]>.create { (observer) -> Disposable in
            self.network.getRequestJSON(url: path, parameters: parameters, headers: nil)
                .debug()
                .subscribe(onNext: { response in
                    if let json = response.result.value as? [String: Any], let eventsJson = json["events"] as? [String: Any] {
                        let events = Event.decodeEvents(eventsJson)
                        //Filter by active or !active
                        let filteredEvents = events.filter { $0.isActive == active}
                        observer.onNext(filteredEvents)
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
    
    func getEventAthletes(_ eventId: String) -> Observable<[Athlete]> {
        let baseUrl = App.sharedInstance.appEnvironment.apiBaseUrl
        let path = baseUrl + WSLApiService.ApiPathEventDetails
        let parameters = self.appendCommonParameters(["eventId" : eventId as AnyObject])

        return Observable<[Athlete]>.create { (observer) -> Disposable in
            self.network.getRequestJSON(url: path, parameters: parameters, headers: nil)
                .debug()
                .subscribe(onNext: { response in
                    if let json = response.result.value as? [String: Any],
                        let athletesJson = json["athletes"] as? [String: Any],
                        let heatsJson = json["heats"] as? [String: Any]{
                        
                        //Decode and sort heats in ascending order
                        let heats = Heat.decodeHeats(heatsJson).sorted { (h1, h2) -> Bool in
                            return h1.heatNumber < h2.heatNumber
                        }
                        
                        //Decodes athletes
                        let athletes = Athlete.decodeAthletes(athletesJson)
                        
                        //Filter all heats in event by those that are not over (i.e. upcoming or currently running)
                        //and then map the athleteIds to Athletes
                        let activeAndUpcomingAthletes = heats.filter{$0.isOver == false}.map({ (h) -> [Athlete?] in
                            h.athleteIds.compactMap { (id) -> Athlete? in
                                var athlete = athletes.first{ (ath) -> Bool in
                                    ath.athleteId == id
                                }
                                //Mark Athletes as active if heat is active
                                athlete?.isActive = h.isActive
                                athlete?.heatNumber = h.heatNumber
                                athlete?.roundId = h.roundId
                                return athlete
                            }
                        }).flatMap{$0}.compactMap{$0}  //Flattens the array of arrays and removes the optionals
                                                                                                                                            
                        observer.onNext(activeAndUpcomingAthletes)
                        observer.onCompleted()
                    } else {
                        observer.onError(NSError(domain: "WSL", code: 0, userInfo:[NSLocalizedDescriptionKey:"Unexpected Athletes JSON"]))
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
    
    func getHeatStatusAthlete(eventId: String, athleteId: String) -> Observable<(Round, Heat)> {
        let baseUrl = App.sharedInstance.appEnvironment.apiBaseUrl
        let path = baseUrl + WSLApiService.ApiPathEventStatus
        let parameters = self.appendCommonParameters(["eventId" : eventId as AnyObject])

        return Observable<(Round, Heat)>.create { (observer) -> Disposable in
            self.network.getRequestJSON(url: path, parameters: parameters, headers: nil)
                .debug()
                .subscribe(onNext: { response in
                    if let json = response.result.value as? [String: Any],
                        let eventsJson = json["events"] as? [String: Any],
                        let event = Event.decodeEvent(eventsJson, eventId: eventId),
                        let heatsJson = json["heats"] as? [String: Any] {
                        if let heat = Heat.decodeHeatAthlete(heatsJson, heatIds: event.currentHeatIds, athleteId: athleteId),
                            let roundsJson = json["rounds"] as? [String: Any],
                            let round = Round.decodeRound(roundsJson, roundId: heat.roundId) {
                            observer.onNext((round, heat))
                            observer.onCompleted()
                        } else {
                            observer.onCompleted()
                        }
                    } else {
                        observer.onError(NSError(domain: "WSL", code: 0, userInfo:[NSLocalizedDescriptionKey:"Unexpected Athletes JSON"]))
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
        
    func logAthleteEventWatchUsage(eventId: String, athleteId: String, roundId: String, heatNumber: Int) -> Observable<(Round, Heat)> {
        let baseUrl = App.sharedInstance.appEnvironment.apiBaseUrl
        let path = baseUrl + WSLApiService.ApiPathLogEventWatchUsage
        let parameters = self.appendCommonParameters(["eventId" : eventId as AnyObject,
                                                      "athleteId" : athleteId as AnyObject,
                                                      "roundId": roundId as AnyObject,
                                                      "heatNumber": heatNumber as AnyObject,
        ])

        return Observable<(Round, Heat)>.create { (observer) -> Disposable in
            self.network.getRequestJSON(url: path, parameters: parameters, headers: nil)
                .debug()
                .subscribe(onNext: { response in
                    if let json = response.result.value as? [String: Any],
                       let resultsJson = json["results"] as? [String: Any],
                       let status = resultsJson["status"] as? String,
                       status == "success" {
                        observer.onCompleted()
                    } else {
                        observer.onError(NSError(domain: "WSL", code: 0, userInfo:[NSLocalizedDescriptionKey:"Unexpected JSON response"]))
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
    
    private func appendCommonParameters(_ params: [String: AnyObject]) -> [String: AnyObject] {
        var commonParams = ["appKey": App.sharedInstance.appEnvironment.apiClientKey as AnyObject]
        commonParams.merge(params) { (current, _) -> AnyObject in
            current
        }
        return commonParams
    }
}
