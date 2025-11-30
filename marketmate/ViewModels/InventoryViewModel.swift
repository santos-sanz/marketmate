import Combine
import Foundation
import Supabase

@MainActor
final class InventoryViewModel: ObservableObject {
  @Published var products: [Product] = []
  @Published var categories: [Category] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  func fetchProducts() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    if let cachedProducts = OfflineService.shared.load([Product].self, from: "products.json") {
      self.products = cachedProducts
    }

    do {
      let products: [Product] = try await client
        .from("products")
        .select()
        .order("created_at", ascending: false)
        .execute()
        .value
      self.products = products
      OfflineService.shared.save(products, to: "products.json")
    } catch {
      errorMessage = "Error fetching products: \(error.localizedDescription)"
    }
  }

  func addProduct(
    name: String, price: Double, cost: Double?, stock: Int?, categoryId: UUID?, description: String?
  ) async {
    guard let userId = client.auth.currentUser?.id else {
      errorMessage = "User not logged in"
      return
    }

    let newProduct = Product(
      id: UUID(),
      userId: userId,
      name: name,
      description: description,
      price: price,
      cost: cost,
      stockQuantity: stock,
      categoryId: categoryId,
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
      let _: Product = try await client
        .from("products")
        .update(product)
        .eq("id", value: product.id)
        .single()
        .execute()
        .value
      await fetchProducts()
    } catch {
      errorMessage = "Error updating product: \(error.localizedDescription)"
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

  func adjustStock(productId: UUID, change: Int) async {
    guard let productIndex = products.firstIndex(where: { $0.id == productId }) else {
      return
    }

    var product = products[productIndex]

    guard let currentStock = product.stockQuantity else { return }
    product.stockQuantity = currentStock + change
    await updateProduct(product)
  }

  func fetchCategories() async {
    do {
      let categories: [Category] = try await client
        .from("categories")
        .select()
        .eq("type", value: "inventory")
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
      type: .inventory,
      createdAt: Date()
    )

    do {
      try await client.from("categories").insert(newCategory).execute()
      await fetchCategories()
    } catch {
      errorMessage = "Error adding category: \(error.localizedDescription)"
    }
  }
}
