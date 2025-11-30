import Combine
import Foundation
import Supabase

@MainActor
final class MarketSessionManager: ObservableObject {
  @Published var activeMarket: Market?
  @Published var isLoading = false

  private let client = SupabaseService.shared.client

  func startMarket(location: String, latitude: Double?, longitude: Double?) async {
    isLoading = true
    defer { isLoading = false }
    guard let userId = client.auth.currentUser?.id else {
      return
    }

    let name = "\(location) - \(Date().formatted(date: .abbreviated, time: .shortened))"
    let newMarket = Market(
      id: UUID(),
      userId: userId,
      name: name,
      location: location,
      latitude: latitude,
      longitude: longitude,
      date: Date(),
      isOpen: true,
      endTime: nil,
      createdAt: Date()
    )

    do {
      try await client.from("markets").insert(newMarket).execute()
      self.activeMarket = newMarket
    } catch {
      activeMarket = nil
    }
  }

  func endMarket() async {
    isLoading = true
    defer { isLoading = false }

    guard let market = activeMarket else { return }

    var updatedMarket = market
    updatedMarket.isOpen = false
    updatedMarket.endTime = Date()

    do {
      try await client.from("markets").update(updatedMarket).eq("id", value: market.id).execute()
      self.activeMarket = nil
    } catch {
      activeMarket = market
    }
  }

  func updateMarket(_ market: Market) async {
    isLoading = true
    defer { isLoading = false }

    do {
      try await client
        .from("markets")
        .update(market)
        .eq("id", value: market.id)
        .execute()

      if activeMarket?.id == market.id {
        self.activeMarket = market
      }
    } catch {
      // Keep the previous active market if update fails
    }
  }

  func checkForActiveMarket() async {
    isLoading = true
    defer { isLoading = false }
    guard let userId = client.auth.currentUser?.id else {
      return
    }

    do {
      let markets: [Market] = try await client
        .from("markets")
        .select()
        .eq("user_id", value: userId)
        .eq("is_open", value: true)
        .order("created_at", ascending: false)
        .limit(1)
        .execute()
        .value

      activeMarket = markets.first
    } catch {
      activeMarket = nil
    }
  }
}
