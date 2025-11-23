import Combine
import Foundation
import Supabase

@MainActor
class CostsViewModel: ObservableObject {
  @Published var costs: [Cost] = []
  @Published var categories: [CostCategory] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  func fetchCosts() async {
    isLoading = true
    errorMessage = nil

    if let cachedCosts = OfflineService.shared.load([Cost].self, from: "costs.json") {
      self.costs = cachedCosts
    }

    do {
      let costs: [Cost] =
        try await client
        .from("costs")
        .select()
        .order("created_at", ascending: false)
        .execute()
        .value

      self.costs = costs
      OfflineService.shared.save(costs, to: "costs.json")
    } catch {
      errorMessage = "Error fetching costs: \(error.localizedDescription)"
    }
    isLoading = false
  }

  func fetchCategories() async {
    do {
      let categories: [CostCategory] = try await client.from("cost_categories").select().execute()
        .value
      self.categories = categories
    } catch {
      print("Error fetching categories: \(error)")
    }
  }

  func addCost(description: String, amount: Double, category: String?, isRecurrent: Bool) async {
    guard let userId = client.auth.currentUser?.id else { return }
    let newCost = Cost(
      id: UUID(),
      userId: userId,
      marketId: nil,
      description: description,
      amount: amount,
      category: category,
      isRecurrent: isRecurrent,
      createdAt: Date()
    )
    do {
      try await client.from("costs").insert(newCost).execute()
      await fetchCosts()
    } catch {
      self.errorMessage = "Error adding cost: \(error.localizedDescription)"
    }
  }

  func updateCost(_ cost: Cost) async {
    do {
      let _: Cost =
        try await client
        .from("costs")
        .update(cost)
        .eq("id", value: cost.id)
        .single()
        .execute()
        .value
      await fetchCosts()
    } catch {
      errorMessage = "Error updating cost: \(error.localizedDescription)"
      print("Error updating cost: \(error)")
    }
  }

  func deleteCost(id: UUID) async {
    do {
      try await client.from("costs").delete().eq("id", value: id).execute()
      await fetchCosts()
    } catch {
      errorMessage = "Error deleting cost: \(error.localizedDescription)"
      print("Error deleting cost: \(error)")
    }
  }
}
