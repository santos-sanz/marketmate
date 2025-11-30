import Combine
import Foundation
import Supabase

@MainActor
final class CostsViewModel: ObservableObject {
  @Published var costs: [Cost] = []
  @Published var categories: [Category] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  func fetchCosts() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    if let cachedCosts = OfflineService.shared.load([Cost].self, from: "costs.json") {
      self.costs = cachedCosts
    }

    do {
      let costs: [Cost] = try await client
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
  }

  func fetchCategories() async {
    do {
      let categories: [Category] = try await client
        .from("categories")
        .select()
        .eq("type", value: "cost")
        .execute()
        .value
      self.categories = categories
    } catch {
      errorMessage = "Error fetching categories: \(error.localizedDescription)"
    }
  }

  func addCategory(name: String) async {
    guard let userId = client.auth.currentUser?.id else {
      errorMessage = "User not logged in"
      return
    }

    let newCategory = Category(
      id: UUID(),
      userId: userId,
      name: name,
      type: .cost,
      createdAt: Date()
    )

    do {
      try await client.from("categories").insert(newCategory).execute()
      await fetchCategories()
    } catch {
      errorMessage = "Error adding category: \(error.localizedDescription)"
    }
  }

  func addCost(description: String, amount: Double, categoryId: UUID?) async {
    guard let userId = client.auth.currentUser?.id else {
      errorMessage = "User not logged in"
      return
    }
    let newCost = Cost(
      id: UUID(),
      userId: userId,
      marketId: nil,
      description: description,
      amount: amount,
      categoryId: categoryId,
      isRecurrent: false,
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
      let _: Cost = try await client
        .from("costs")
        .update(cost)
        .eq("id", value: cost.id)
        .single()
        .execute()
        .value
      await fetchCosts()
    } catch {
      errorMessage = "Error updating cost: \(error.localizedDescription)"
    }
  }

  func deleteCost(id: UUID) async {
    do {
      try await client.from("costs").delete().eq("id", value: id).execute()
      await fetchCosts()
    } catch {
      errorMessage = "Error deleting cost: \(error.localizedDescription)"
    }
  }
}
