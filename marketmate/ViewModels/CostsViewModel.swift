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
    print("💰 [CostsVM] Fetching costs...")
    isLoading = true
    errorMessage = nil

    if let cachedCosts = OfflineService.shared.load([Cost].self, from: "costs.json") {
      self.costs = cachedCosts
      print("💰 [CostsVM] Loaded \(cachedCosts.count) costs from cache")
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
      print("✅ [CostsVM] Fetched \(costs.count) costs successfully")
    } catch {
      errorMessage = "Error fetching costs: \(error.localizedDescription)"
      print("❌ [CostsVM] Error fetching costs: \(error)")
    }
    isLoading = false
  }

  func fetchCategories() async {
    print("💰 [CostsVM] Fetching categories...")
    do {
      let categories: [CostCategory] = try await client.from("cost_categories").select().execute()
        .value
      self.categories = categories
      print("✅ [CostsVM] Fetched \(categories.count) categories successfully")
    } catch {
      print("❌ [CostsVM] Error fetching categories: \(error)")
    }
  }

  func addCost(description: String, amount: Double, category: String?, isRecurrent: Bool) async {
    print("💰 [CostsVM] Adding cost: \(description)")
    guard let userId = client.auth.currentUser?.id else {
      print("❌ [CostsVM] No user ID found")
      return
    }
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
      print("✅ [CostsVM] Cost added successfully")
      await fetchCosts()
    } catch {
      self.errorMessage = "Error adding cost: \(error.localizedDescription)"
      print("❌ [CostsVM] Error adding cost: \(error)")
    }
  }

  func updateCost(_ cost: Cost) async {
    print("💰 [CostsVM] Updating cost: \(cost.description)")
    do {
      let _: Cost =
        try await client
        .from("costs")
        .update(cost)
        .eq("id", value: cost.id)
        .single()
        .execute()
        .value
      print("✅ [CostsVM] Cost updated successfully")
      await fetchCosts()
    } catch {
      errorMessage = "Error updating cost: \(error.localizedDescription)"
      print("❌ [CostsVM] Error updating cost: \(error)")
    }
  }

  func deleteCost(id: UUID) async {
    print("💰 [CostsVM] Deleting cost: \(id)")
    do {
      try await client.from("costs").delete().eq("id", value: id).execute()
      print("✅ [CostsVM] Cost deleted successfully")
      await fetchCosts()
    } catch {
      errorMessage = "Error deleting cost: \(error.localizedDescription)"
      print("❌ [CostsVM] Error deleting cost: \(error)")
    }
  }
}
