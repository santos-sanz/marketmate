import Combine
import Foundation
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
  @Published var profile: UserProfile?
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var selectedCurrency: String = "USD"  // Default

  var currencySymbol: String {
    switch selectedCurrency {
    case "USD": return "$"
    case "EUR": return "€"
    case "GBP": return "£"
    case "JPY": return "¥"
    case "AUD": return "A$"
    case "CAD": return "C$"
    default: return selectedCurrency
    }
  }

  private let client = SupabaseService.shared.client

  func fetchProfile() async {
    guard let userId = client.auth.currentUser?.id else {
      print("❌ [ProfileVM] No user ID found")
      return
    }
    print("👤 [ProfileVM] Fetching profile for user: \(userId)")
    isLoading = true
    do {
      let profile: UserProfile =
        try await client
        .from("profiles")
        .select()
        .eq("id", value: userId)
        .single()
        .execute()
        .value

      self.profile = profile
      if let currency = profile.currency {
        self.selectedCurrency = currency
      }
      print("✅ [ProfileVM] Profile fetched successfully. Currency: \(selectedCurrency)")
    } catch {
      print("❌ [ProfileVM] Error fetching profile: \(error)")
      // If profile doesn't exist, we might need to create it, but usually triggers handle that.
    }
    isLoading = false
  }

  func updateCurrency(_ currency: String) async {
    guard let userId = client.auth.currentUser?.id else {
      print("❌ [ProfileVM] No user ID found")
      return
    }
    print("👤 [ProfileVM] Updating currency to: \(currency)")
    isLoading = true
    do {
      let updateData = ["currency": currency]
      try await client
        .from("profiles")
        .update(updateData)
        .eq("id", value: userId)
        .execute()

      self.selectedCurrency = currency
      // Update local profile object as well
      if var currentProfile = profile {
        currentProfile.currency = currency
        self.profile = currentProfile
      }
      print("✅ [ProfileVM] Currency updated successfully")
    } catch {
      errorMessage = "Failed to update currency: \(error.localizedDescription)"
      print("❌ [ProfileVM] Error updating currency: \(error)")
    }
    isLoading = false
  }

  func signOut() async {
    print("👤 [ProfileVM] Signing out...")
    do {
      try await client.auth.signOut()
      print("✅ [ProfileVM] Signed out successfully")
    } catch {
      errorMessage = error.localizedDescription
      print("❌ [ProfileVM] Error signing out: \(error)")
    }
  }

  func exportData() async -> URL? {
    print("👤 [ProfileVM] Exporting data...")
    isLoading = true
    defer { isLoading = false }

    do {
      guard let userId = client.auth.currentUser?.id else {
        print("❌ [ProfileVM] No user ID found for export")
        return nil
      }

      // Fetch Sales
      let sales: [Sale] = try await client.from("sales").select().eq("user_id", value: userId)
        .execute().value

      // Fetch Costs
      let costs: [Cost] = try await client.from("costs").select().eq("user_id", value: userId)
        .execute().value

      // Generate CSV
      var csvString = "Type,Date,Amount,Description,Payment Method\n"

      for sale in sales {
        let date = sale.createdAt.formatted(date: .numeric, time: .shortened)
        let line = "Sale,\(date),\(sale.totalAmount),Sale ID: \(sale.id),\(sale.paymentMethod)\n"
        csvString.append(line)
      }

      for cost in costs {
        let date = cost.createdAt.formatted(date: .numeric, time: .shortened)
        let line = "Cost,\(date),\(cost.amount),\(cost.description),-\n"
        csvString.append(line)
      }

      // Save to Temp File
      let fileName =
        "MarketMate_Data_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"
      let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
      try csvString.write(to: path, atomically: true, encoding: .utf8)

      print("✅ [ProfileVM] Data exported successfully to: \(path)")
      return path
    } catch {
      errorMessage = "Failed to export data: \(error.localizedDescription)"
      print("❌ [ProfileVM] Error exporting data: \(error)")
      return nil
    }
  }

  func deleteAccount() async {
    print("👤 [ProfileVM] Deleting account...")
    isLoading = true
    errorMessage = nil

    do {
      // Verify we have a valid session before attempting deletion
      guard let userId = client.auth.currentUser?.id else {
        errorMessage = "No user session found. Please sign in again."
        print("❌ [ProfileVM] No user ID found for deletion")
        isLoading = false
        return
      }

      print("👤 [ProfileVM] Invoking delete-account Edge Function for user: \(userId)")

      // ATOMIC OPERATION: Invoke Edge Function to delete user from auth.users
      // This triggers cascade delete of all user data and invalidates all JWT tokens
      let _: Void = try await client.functions.invoke("delete-account")

      print("✅ [ProfileVM] Account deleted successfully via Edge Function")

      // At this point, the user is deleted and JWT is invalidated server-side
      // Clean up local state - this MUST happen regardless of signOut result
      self.profile = nil
      self.selectedCurrency = "USD"

      // Attempt to sign out locally to clear session storage
      // We don't throw if this fails because the user is already deleted server-side
      do {
        try await client.auth.signOut()
        print("✅ [ProfileVM] Local session cleared")
      } catch {
        // Log but don't fail - user is already deleted server-side
        print("⚠️ [ProfileVM] Local signOut failed but user already deleted: \(error)")
      }

    } catch {
      // Only show error if Edge Function failed (user NOT deleted)
      // Try to extract detailed error message from response
      let detailedError: String
      if let httpError = error as? URLError {
        detailedError = "Network error: \(httpError.localizedDescription)"
      } else {
        // Try to extract error from the response data
        let errorString = String(describing: error)
        if errorString.contains("httpError") {
          // The error likely contains JSON response data
          detailedError =
            "Server error (400). Please check:\n1. Edge Function has SUPABASE_SERVICE_ROLE_KEY secret configured\n2. Edge Function logs in Supabase Dashboard for details"
        } else {
          detailedError = error.localizedDescription
        }
      }

      errorMessage = "Failed to delete account: \(detailedError)"
      print("❌ [ProfileVM] Error deleting account:")
      print("   Error type: \(type(of: error))")
      print("   Error description: \(error)")
      print("   Localized: \(error.localizedDescription)")
    }

    isLoading = false
  }
}
