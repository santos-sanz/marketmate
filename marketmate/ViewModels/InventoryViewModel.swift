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
    print("📦 [InventoryVM] Fetching products...")
    isLoading = true
    errorMessage = nil

    // Try to load from cache first for immediate UI
    if let cachedProducts = OfflineService.shared.load([Product].self, from: "products.json") {
      self.products = cachedProducts
      print("📦 [InventoryVM] Loaded \(cachedProducts.count) products from cache")
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
      print("✅ [InventoryVM] Fetched \(products.count) products successfully")
    } catch {
      errorMessage = "Error fetching products: \(error.localizedDescription)"
      print("❌ [InventoryVM] Error fetching products: \(error)")
    }
    isLoading = false
  }

  func addProduct(
    name: String, price: Double, cost: Double?, stock: Int?, category: String?, description: String?
  ) async {
    print("📦 [InventoryVM] Adding product: \(name)")
    guard let userId = client.auth.currentUser?.id else {
      print("❌ [InventoryVM] No user ID found")
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
      category: category,
      imageUrl: nil,
      createdAt: Date()
    )

    do {
      try await client.from("products").insert(newProduct).execute()
      print("✅ [InventoryVM] Product added successfully")
      await fetchProducts()
    } catch {
      self.errorMessage = "Error adding product: \(error.localizedDescription)"
      print("❌ [InventoryVM] Error adding product: \(error)")
    }
  }

  func updateProduct(_ product: Product) async {
    print("📦 [InventoryVM] Updating product: \(product.name)")
    do {
      let _: Product =
        try await client
        .from("products")
        .update(product)
        .eq("id", value: product.id)
        .single()
        .execute()
        .value
      print("✅ [InventoryVM] Product updated successfully")
      await fetchProducts()
    } catch {
      errorMessage = "Error updating product: \(error.localizedDescription)"
      print("❌ [InventoryVM] Error updating product: \(error)")
    }
  }

  func deleteProduct(id: UUID) async {
    print("📦 [InventoryVM] Deleting product: \(id)")

    do {
      try await client.from("products").delete().eq("id", value: id).execute()
      print("✅ [InventoryVM] Product deleted successfully")
      await fetchProducts()
    } catch {
      self.errorMessage = "Error deleting product: \(error.localizedDescription)"
      print("❌ [InventoryVM] Error deleting product: \(error)")
    }
  }
  func adjustStock(productId: UUID, change: Int) async {
    print("📦 [InventoryVM] Adjusting stock for \(productId) by \(change)")
    
    // 1. Get current product
    guard let productIndex = products.firstIndex(where: { $0.id == productId }) else {
      print("❌ [InventoryVM] Product not found in local cache")
      return
    }
    
    var product = products[productIndex]
    
    // 2. Update local stock
    if let currentStock = product.stockQuantity {
      let newStock = currentStock + change
      product.stockQuantity = newStock
      
      // 3. Update in DB
      await updateProduct(product)
    } else {
      print("⚠️ [InventoryVM] Product has no stock tracking")
    }
  }
}
