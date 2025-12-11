import Foundation
import CoreLocation

class GeofencingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = GeofencingManager()
    @Published var userLocation: CLLocation?
    @Published var isHome: Bool = false
    
    private let locationManager = CLLocationManager()
    
    override private init() {
        super.init()
        locationManager.delegate = self
    }

    /// Cleans up resources to prevent memory leaks
    ///
    /// **Memory Safety**: Critical - clears CLLocationManager delegate to break retain cycle
    deinit {
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
    }

    func startMonitoring(homeLocation: CLLocationCoordinate2D, radius: CLLocationDistance) {
        let region = CLCircularRegion(center: homeLocation, radius: radius, identifier: "home")
        locationManager.startMonitoring(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        isHome = true
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        isHome = false
    }
}