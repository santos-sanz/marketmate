import SwiftUI

struct ContentView: View {
  @StateObject private var authVM = AuthViewModel()
  @StateObject private var profileVM = ProfileViewModel()
  @StateObject private var themeManager = ThemeManager()
  @AppStorage("isDarkMode") private var isDarkMode = true

  var body: some View {
    Group {
      if authVM.isAuthenticated {
        MainTabView()
          .environmentObject(authVM)
          .environmentObject(profileVM)
          .environmentObject(themeManager)
          .task {
            await profileVM.fetchProfile()
          }
      } else {
        AuthView()
          .environmentObject(authVM)
          .environmentObject(themeManager)
      }
    }
    .background(themeManager.backgroundColor.ignoresSafeArea())
    .tint(themeManager.primaryTextColor)
    .preferredColorScheme(isDarkMode ? .dark : .light)
    .onChange(of: profileVM.themeBackgroundHex) { newValue in
      themeManager.apply(backgroundHex: newValue, textHex: profileVM.themeTextHex)
    }
    .onChange(of: profileVM.themeTextHex) { newValue in
      themeManager.apply(backgroundHex: profileVM.themeBackgroundHex, textHex: newValue)
    }
  }
}

#Preview {
  ContentView()
}
