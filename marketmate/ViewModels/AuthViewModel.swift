import Combine
import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
  @Published var email = ""
  @Published var password = ""
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var isAuthenticated = false

  private let client = SupabaseService.shared.client

  var currentUserEmail: String? {
    client.auth.currentUser?.email
  }

  init() {
    Task {
      await checkSession()
    }
  }

  func checkSession() async {
    print("🔐 [AuthVM] Checking session...")
    do {
      _ = try await client.auth.session
      isAuthenticated = true
      print("✅ [AuthVM] Session valid, user authenticated")
    } catch {
      isAuthenticated = false
      print("❌ [AuthVM] No valid session found")
    }
  }

  func signUp() async {
    print("🔐 [AuthVM] Signing up user: \(email)")
    isLoading = true
    errorMessage = nil
    do {
      _ = try await client.auth.signUp(email: email, password: password)
      print("✅ [AuthVM] Sign up successful")
      // For simplicity in this MVP, we might auto-signin or ask to confirm email.
      // Supabase default is confirm email, but we can check if session is created.
      await checkSession()
    } catch {
      print("❌ [AuthVM] Sign Up Error: \(error)")
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func signIn() async {
    print("🔐 [AuthVM] Signing in user: \(email)")
    isLoading = true
    errorMessage = nil
    do {
      _ = try await client.auth.signIn(email: email, password: password)
      isAuthenticated = true
      print("✅ [AuthVM] Sign in successful")
    } catch {
      print("❌ [AuthVM] Sign In Error: \(error)")
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func signOut() async {
    print("🔐 [AuthVM] Signing out...")
    isLoading = true
    do {
      try await client.auth.signOut()
      isAuthenticated = false
      print("✅ [AuthVM] Sign out successful")
    } catch {
      errorMessage = error.localizedDescription
      print("❌ [AuthVM] Sign out error: \(error)")
    }
    isLoading = false
  }
}
