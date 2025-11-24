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
    do {
      guard let userId = client.auth.currentUser?.id else {
        print("❌ [ProfileVM] No user ID found for deletion")
        return
      }

      // Delete Profile (Assuming Cascade Delete is set up in Supabase for related data)
      try await client.from("profiles").delete().eq("id", value: userId).execute()

      // Sign Out
      try await client.auth.signOut()
      print("✅ [ProfileVM] Account deleted successfully")
    } catch {
      errorMessage = "Failed to delete account: \(error.localizedDescription)"
      print("❌ [ProfileVM] Error deleting account: \(error)")
    }
    isLoading = false
  }
}
