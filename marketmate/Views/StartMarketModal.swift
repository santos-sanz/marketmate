import CoreLocation
import SwiftUI

struct StartMarketModal: View {
  @Binding var isPresented: Bool
  @Binding var marketName: String
  @ObservedObject var locationManager: LocationManager
  let onStart: () -> Void

  @State private var showingPermissionAlert = false

  var body: some View {
    ZStack {
      // Dimmed background
      Color.black.opacity(0.4)
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
          isPresented = false
        }

      // Modal Content
      VStack(spacing: 20) {
        Text("Open Market")
          .font(Typography.title3)
          .foregroundColor(.black)
          .bold()

        Text("Click the location button to autofill the text.")
          .font(Typography.caption1)
          .foregroundColor(.gray)
          .multilineTextAlignment(.center)

        HStack(spacing: 12) {
          TextField("Market Name", text: $marketName)
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.black)

          Button(action: {
            autoFillLocation()
          }) {
            Image(systemName: "location.fill")
              .font(.system(size: 20))
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
              .background(Color.marketBlue)
              .cornerRadius(8)
          }
        }

        HStack(spacing: 12) {
          Button(action: {
            isPresented = false
          }) {
            Text("Cancel")
              .font(Typography.body)
              .foregroundColor(.gray)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.gray.opacity(0.1))
              .cornerRadius(12)
          }

          Button(action: {
            onStart()
          }) {
            Text("Start")
              .font(Typography.body)
              .bold()
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.marketBlue)
              .cornerRadius(12)
          }
        }
      }
      .padding(24)
      .background(Color.white)
      .cornerRadius(20)
      .padding(.horizontal, 40)
      .shadow(radius: 10)
    }
    .alert("Location Access Denied", isPresented: $showingPermissionAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Please enter the market name manually.")
    }
    .onChange(of: locationManager.authorizationStatus) { status in
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
