import Combine
import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
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
    isAuthenticated = (try? await client.auth.session) != nil
  }

  func signUp() async {
    await performAuth {
      _ = try await client.auth.signUp(email: email, password: password)
      await checkSession()
    }
  }

  func signIn() async {
    await performAuth {
      _ = try await client.auth.signIn(email: email, password: password)
      isAuthenticated = true
    }
  }

  func signOut() async {
    await performAuth {
      try await client.auth.signOut()
      isAuthenticated = false
    }
  }

  private func performAuth(_ action: () async throws -> Void) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      try await action()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
