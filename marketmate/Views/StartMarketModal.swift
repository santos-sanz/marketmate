import CoreLocation
import SwiftUI

struct StartMarketModal: View {
  @Binding var isPresented: Bool
  @Binding var marketName: String
  @ObservedObject var locationManager: LocationManager
  let onStart: () -> Void

  @State private var showingPermissionAlert = false
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    ZStack {
      // Dimmed background
      themeManager.backgroundColor.opacity(0.85)
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
          isPresented = false
        }

      // Modal Content
      VStack(spacing: 20) {
        Text("Open Market")
          .font(Typography.title3)
          .foregroundColor(themeManager.primaryTextColor)
          .bold()

        Text("Click the location button to autofill the text.")
          .font(Typography.caption1)
          .foregroundColor(themeManager.secondaryTextColor)
          .multilineTextAlignment(.center)

        HStack(spacing: 12) {
          TextField("Market Name", text: $marketName)
            .padding(12)
            .background(themeManager.fieldBackground)
            .cornerRadius(8)
            .foregroundColor(themeManager.primaryTextColor)

          Button(action: {
            autoFillLocation()
          }) {
            Image(systemName: "location.fill")
              .font(.system(size: 20))
              .foregroundColor(themeManager.primaryTextColor)
              .frame(width: 44, height: 44)
              .background(themeManager.translucentOverlay)
              .cornerRadius(8)
          }
        }

        HStack(spacing: 12) {
          Button(action: {
            isPresented = false
          }) {
            Text("Cancel")
              .font(Typography.body)
              .foregroundColor(themeManager.secondaryTextColor)
              .frame(maxWidth: .infinity)
              .padding()
              .background(themeManager.fieldBackground)
              .cornerRadius(12)
          }

          Button(action: {
            onStart()
          }) {
            Text("Start")
              .font(Typography.body)
              .bold()
              .foregroundColor(themeManager.primaryTextColor)
              .frame(maxWidth: .infinity)
              .padding()
              .background(themeManager.primaryTextColor.opacity(0.12))
              .cornerRadius(12)
          }
        }
      }
      .padding(24)
      .background(themeManager.elevatedCardBackground)
      .cornerRadius(20)
      .padding(.horizontal, 40)
      .shadow(color: themeManager.strokeColor, radius: 10)
    }
    .alert("Location Access Denied", isPresented: $showingPermissionAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Please enter the market name manually.")
    }
    .onChange(of: locationManager.authorizationStatus) { _, status in
      if status == .denied || status == .restricted {
        showingPermissionAlert = true
        locationManager.stopUpdatingLocation()
      }
    }
  }

  private func autoFillLocation() {
    let status = locationManager.authorizationStatus

    if status == .denied || status == .restricted {
      showingPermissionAlert = true
      return
    }

    if status == .notDetermined {
      locationManager.requestPermission()
    }

    locationManager.startUpdatingLocation()

    // Wait briefly for location update then reverse geocode
    // In a real app we might want to listen to the publisher, but for this simple action:
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      if let location = locationManager.location {
        Task {
          if let city = await locationManager.reverseGeocode(location: location) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM yyyy"
            let dateString = dateFormatter.string(from: Date())
            marketName = "\(city) - \(dateString)"
          }
          locationManager.stopUpdatingLocation()
        }
      }
    }
  }
}
