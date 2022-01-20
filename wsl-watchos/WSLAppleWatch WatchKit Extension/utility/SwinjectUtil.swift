
import Foundation
import Swinject

class SwinjectUtil {
    static let sharedInstance = SwinjectUtil()
    
    fileprivate init() {}
    
    let container = Container() { container in

        container.register(NetworkingService.self) { _ in
            Network()
            }.inObjectScope(.container) // Singleton

        container.register(WSLApiService.self) { r in
            WSLApiService(network: r.resolve(NetworkingService.self)!)
            }.inObjectScope(.container) // Singleton

        container.register(WSLPushService.self) { r in
            WSLPushService(network: r.resolve(NetworkingService.self)!)
            }.inObjectScope(.container) // Singleton
        
        container.register(ToursViewModel.self) { r in
            ToursViewModel(wslApiService: r.resolve(WSLApiService.self)!, wslPushService: r.resolve(WSLPushService.self)!)
        }
    }
}
