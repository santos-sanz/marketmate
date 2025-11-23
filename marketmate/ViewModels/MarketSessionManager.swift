import Combine
import Foundation
import Supabase

@MainActor
class MarketSessionManager: ObservableObject {
  @Published var activeMarket: Market?
  @Published var isLoading = false

  private let client = SupabaseService.shared.client

  func startMarket(location: String, latitude: Double?, longitude: Double?) async {
    isLoading = true
    guard let userId = client.auth.currentUser?.id else { return }

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
      createdAt: Date()
    )

    do {
      try await client.from("markets").insert(newMarket).execute()
      self.activeMarket = newMarket
    } catch {
      print("Error starting market: \(error)")
    }
    isLoading = false
  }

  func endMarket() async {
    guard let market = activeMarket else { return }
    isLoading = true

    var updatedMarket = market
    updatedMarket.isOpen = false

    do {
      try await client.from("markets").update(updatedMarket).eq("id", value: market.id).execute()
      self.activeMarket = nil
    } catch {
      print("Error ending market: \(error)")
    }
    isLoading = false
  }
}
