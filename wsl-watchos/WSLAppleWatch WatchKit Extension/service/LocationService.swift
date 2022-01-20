

import Foundation
import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = LocationService()
    
    let manager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func startTrackingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopTrackingLocation() {
        manager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> CLLocation? {
        return currentLocation
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.last else {
            return
        }
        
        self.currentLocation = location
    }
}
