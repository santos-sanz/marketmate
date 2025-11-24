import Combine
import Foundation
import Supabase

@MainActor
class MarketSessionManager: ObservableObject {
  @Published var activeMarket: Market?
  @Published var isLoading = false

  private let client = SupabaseService.shared.client

  func startMarket(location: String, latitude: Double?, longitude: Double?) async {
    print("Starting market at: \(location)")
    isLoading = true
    guard let userId = client.auth.currentUser?.id else {
      print("Error: No current user ID found")
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
      print("Inserting new market: \(newMarket)")
      try await client.from("markets").insert(newMarket).execute()
      self.activeMarket = newMarket
      print("Market started successfully")
    } catch {
      print("Error starting market: \(error)")
    }
    isLoading = false
  }

  func endMarket() async {
    guard let market = activeMarket else {
      print("Error: No active market to end")
      return
    }
    print("Ending market: \(market.id)")
    isLoading = true

    var updatedMarket = market
    updatedMarket.isOpen = false
    updatedMarket.endTime = Date()

    do {
      try await client.from("markets").update(updatedMarket).eq("id", value: market.id).execute()
      print("Market ended successfully")
      self.activeMarket = nil
    } catch {
      print("Error ending market: \(error)")
    }
    isLoading = false
  }

  func updateMarket(_ market: Market) async {
    print("Updating market: \(market.name)")
    isLoading = true

    do {
      try await client
        .from("markets")
        .update(market)
        .eq("id", value: market.id)
        .execute()

      if activeMarket?.id == market.id {
        self.activeMarket = market
      }
      print("Market updated successfully")
    } catch {
      print("Error updating market: \(error)")
    }
    isLoading = false
  }

  func checkForActiveMarket() async {
    print("Checking for active market...")
    isLoading = true
    guard let userId = client.auth.currentUser?.id else {
      print("Error: No current user ID found for check")
      return
    }

    do {
      let markets: [Market] =
        try await client
        .from("markets")
        .select()
        .eq("user_id", value: userId)
        .eq("is_open", value: true)
        .order("created_at", ascending: false)
        .limit(1)
        .execute()
        .value

      if let market = markets.first {
        self.activeMarket = market
        print("Found active market: \(market.name)")
      } else {
        print("No active market found")
      }
    } catch {
      print("Error checking for active market: \(error)")
    }
    isLoading = false
  }
}
