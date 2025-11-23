import Combine
import Foundation
import Supabase

@MainActor
class InventoryViewModel: ObservableObject {
  @Published var products: [Product] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  func fetchProducts() async {
    isLoading = true
    errorMessage = nil

    // Try to load from cache first for immediate UI
    if let cachedProducts = OfflineService.shared.load([Product].self, from: "products.json") {
      self.products = cachedProducts
    }

    do {
      let products: [Product] =
        try await client
        .from("products")
        .select()
        .order("created_at", ascending: false)
        .execute()
        .value
      self.products = products
      OfflineService.shared.save(products, to: "products.json")
    } catch {
      errorMessage = "Error fetching products: \(error.localizedDescription)"
      print("Error fetching products: \(error)")
    }
    isLoading = false
  }

  func addProduct(
    name: String, price: Double, cost: Double?, stock: Int?, category: String?, description: String?
  ) async {
    guard let userId = client.auth.currentUser?.id else { return }

    let newProduct = Product(
      id: UUID(),
      userId: userId,
      name: name,
      description: description,
      price: price,
      cost: cost,
      stockQuantity: stock,
      category: category,
      imageUrl: nil,
      createdAt: Date()
    )

    do {
      try await client.from("products").insert(newProduct).execute()
      await fetchProducts()
    } catch {
      self.errorMessage = "Error adding product: \(error.localizedDescription)"
    }
  }

  func updateProduct(_ product: Product) async {
    do {
      let _: Product =
        try await client
        .from("products")
        .update(product)
        .eq("id", value: product.id)
        .single()
        .execute()
        .value
      await fetchProducts()
    } catch {
      errorMessage = "Error updating product: \(error.localizedDescription)"
      print("Error updating product: \(error)")
    }
  }

  func deleteProduct(id: UUID) async {
    do {
      try await client.from("products").delete().eq("id", value: id).execute()
      await fetchProducts()
    } catch {
      self.errorMessage = "Error deleting product: \(error.localizedDescription)"
    }
  }
}
