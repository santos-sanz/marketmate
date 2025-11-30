import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  @Published var location: CLLocation?
  @Published var authorizationStatus: CLAuthorizationStatus?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    authorizationStatus = locationManager.authorizationStatus
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
    // Keep silent to avoid spamming logs; UI can observe nil location if needed.
  }

  func reverseGeocode(location: CLLocation) async -> String? {
    let geocoder = CLGeocoder()
    do {
      let placemarks = try await geocoder.reverseGeocodeLocation(location)
      if let placemark = placemarks.first, let city = placemark.locality {
        return city
      }
      return nil
    } catch {
      return nil
    }
  }
}
