import Combine
import CoreLocation
import Foundation

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  @Published var location: CLLocation?
  @Published var authorizationStatus: CLAuthorizationStatus?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
  }

  func requestPermission() {
    locationManager.requestWhenInUseAuthorization()
  }

  func startUpdatingLocation() {
    locationManager.startUpdatingLocation()
  }

  func stopUpdatingLocation() {
    locationManager.stopUpdatingLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    self.location = location
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location manager failed with error: \(error.localizedDescription)")
  }
}
