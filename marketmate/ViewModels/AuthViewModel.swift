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
    do {
      _ = try await client.auth.session
      isAuthenticated = true
    } catch {
      isAuthenticated = false
    }
  }

  func signUp() async {
    isLoading = true
    errorMessage = nil
    do {
      _ = try await client.auth.signUp(email: email, password: password)
      // For simplicity in this MVP, we might auto-signin or ask to confirm email.
      // Supabase default is confirm email, but we can check if session is created.
      await checkSession()
    } catch {
      print("Sign Up Error: \(error)")
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func signIn() async {
    isLoading = true
    errorMessage = nil
    do {
      _ = try await client.auth.signIn(email: email, password: password)
      isAuthenticated = true
    } catch {
      print("Sign In Error: \(error)")
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  func signOut() async {
    isLoading = true
    do {
      try await client.auth.signOut()
      isAuthenticated = false
    } catch {
      errorMessage = error.localizedDescription
    }
    isLoading = false
  }
}
