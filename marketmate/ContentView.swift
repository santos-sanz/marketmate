import SwiftUI

struct ContentView: View {
  @StateObject private var authVM = AuthViewModel()
  @StateObject private var profileVM = ProfileViewModel()
  @AppStorage("isDarkMode") private var isDarkMode = true

  var body: some View {
    Group {
      if authVM.isAuthenticated {
        MainTabView()
          .environmentObject(authVM)
          .environmentObject(profileVM)
          .task {
            await profileVM.fetchProfile()
          }
      } else {
        AuthView()
          .environmentObject(authVM)
      }
    }
    .preferredColorScheme(isDarkMode ? .dark : .light)
  }
}

#Preview {
  ContentView()
}
