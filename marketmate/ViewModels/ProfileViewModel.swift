import Combine
import Foundation
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {
  @Published var profile: UserProfile?
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var selectedCurrency: String = "USD"  // Default
  @Published var useInventory: Bool = true
  @Published var themeBackgroundHex: String = ThemeDefaults.backgroundHex
  @Published var themeTextHex: String = ThemeDefaults.textHex

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
  private var themeUpdateTask: Task<Void, Never>?

  deinit {
    themeUpdateTask?.cancel()
  }

  func fetchProfile() async {
    guard let userId = client.auth.currentUser?.id else { return }
    isLoading = true
    defer { isLoading = false }
    do {
      let profile: UserProfile = try await client
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
      if let useInventory = profile.useInventory {
        self.useInventory = useInventory
      }
      themeBackgroundHex = (profile.themeBackground ?? ThemeDefaults.backgroundHex).uppercased()
      themeTextHex = (profile.themeText ?? ThemeDefaults.textHex).uppercased()
    } catch {
      errorMessage = "Failed to load profile"
    }
  }

  func updateCurrency(_ currency: String) async {
    guard let userId = client.auth.currentUser?.id else { return }
    isLoading = true
    defer { isLoading = false }
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
    } catch {
      errorMessage = "Failed to update currency: \(error.localizedDescription)"
    }
  }

  func updateUseInventory(_ enabled: Bool) async {
    guard let userId = client.auth.currentUser?.id else { return }
    isLoading = true
    defer { isLoading = false }
    do {
      let updateData = ["use_inventory": enabled]
      try await client
        .from("profiles")
        .update(updateData)
        .eq("id", value: userId)
        .execute()

      self.useInventory = enabled
      if var currentProfile = profile {
        currentProfile.useInventory = enabled
        self.profile = currentProfile
      }
    } catch {
      errorMessage = "Failed to update settings: \(error.localizedDescription)"
    }
  }

  func updateTheme(backgroundHex: String, textHex: String) async {
    guard let userId = client.auth.currentUser?.id else { return }

    let normalizedBackground = backgroundHex.uppercased()
    let normalizedText = textHex.uppercased()

    do {
      let updateData: [String: String] = [
        "theme_background": normalizedBackground,
        "theme_text": normalizedText,
      ]

      try await client
        .from("profiles")
        .update(updateData)
        .eq("id", value: userId)
        .execute()

      themeBackgroundHex = normalizedBackground
      themeTextHex = normalizedText

      if var currentProfile = profile {
        currentProfile.themeBackground = normalizedBackground
        currentProfile.themeText = normalizedText
        self.profile = currentProfile
      }
    } catch {
      errorMessage = "Failed to update theme: \(error.localizedDescription)"
    }
  }

  func scheduleThemeUpdate(backgroundHex: String, textHex: String) {
    themeUpdateTask?.cancel()
    themeUpdateTask = Task { [weak self] in
      try? await Task.sleep(nanoseconds: 400_000_000)  // Debounce rapid color changes
      guard !Task.isCancelled else { return }
      await self?.updateTheme(backgroundHex: backgroundHex, textHex: textHex)
    }
  }

  func signOut() async {
    do {
      try await client.auth.signOut()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func exportData() async -> URL? {
    isLoading = true
    defer { isLoading = false }

    do {
      guard let userId = client.auth.currentUser?.id else {
        errorMessage = "User not logged in"
        return nil
      }

      let sales: [Sale] = try await client.from("sales").select().eq("user_id", value: userId)
        .execute().value

      let costs: [Cost] = try await client.from("costs").select().eq("user_id", value: userId)
        .execute().value

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

      let fileName =
        "MarketMate_Data_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"
      let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
      try csvString.write(to: path, atomically: true, encoding: .utf8)

      return path
    } catch {
      errorMessage = "Failed to export data: \(error.localizedDescription)"
      return nil
    }
  }

  func deleteAccount() async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil

    do {
      guard let userId = client.auth.currentUser?.id else {
        errorMessage = "No user session found. Please sign in again."
        return
      }

      let _: Void = try await client.functions.invoke("delete-account")

      self.profile = nil
      self.selectedCurrency = "USD"
      self.useInventory = true
      themeBackgroundHex = ThemeDefaults.backgroundHex
      themeTextHex = ThemeDefaults.textHex

      do {
        try await client.auth.signOut()
      } catch {
        // No-op: user already removed server-side
      }

    } catch {
      errorMessage = "Failed to delete account: \(error.localizedDescription)"
    }
  }
}
