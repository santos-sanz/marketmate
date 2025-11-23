import Combine
import Foundation
import Supabase

struct CartItem: Identifiable {
  let id = UUID()
  let product: Product
  var quantity: Int
}

@MainActor
class SalesViewModel: ObservableObject {
  @Published var sales: [Sale] = []
  @Published var cartItems: [CartItem] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  var cartTotal: Double {
    cartItems.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
  }

  func addToCart(product: Product) {
    if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
      cartItems[index].quantity += 1
    } else {
      cartItems.append(CartItem(product: product, quantity: 1))
    }
  }

  func removeFromCart(product: Product) {
    if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
      if cartItems[index].quantity > 1 {
        cartItems[index].quantity -= 1
      } else {
        cartItems.remove(at: index)
      }
    }
  }

  func clearCart() {
    cartItems.removeAll()
  }

  func fetchSales() async {
    isLoading = true
    errorMessage = nil

    if let cachedSales = OfflineService.shared.load([Sale].self, from: "sales.json") {
      self.sales = cachedSales
    }

    do {
      let sales: [Sale] =
        try await client
        .from("sales")
        .select()
        .order("created_at", ascending: false)
        .execute()
        .value

      self.sales = sales
      OfflineService.shared.save(sales, to: "sales.json")
    } catch {
      errorMessage = "Error fetching sales: \(error.localizedDescription)"
    }
    isLoading = false
  }

  func createSale(
    items: [SaleItem], total: Double, paymentMethod: String, source: String?, notes: String?,
    marketId: UUID?
  ) async {
    guard let userId = client.auth.currentUser?.id else { return }
    let saleId = UUID()
    do {
      // 1. Create Sale
      let newSale = Sale(
        id: saleId,
        userId: userId,
        marketId: marketId,
        totalAmount: total,
        paymentMethod: paymentMethod,
        source: source,
        notes: notes,
        createdAt: Date()
      )

      print("Attempting to create sale: \(newSale)")
      try await client.from("sales").insert(newSale).execute()
      print("Sale created successfully")

      // 2. Create Sale Items
      // Assuming 'items' here are SaleItem objects as per the function signature.
      // The provided snippet's SaleItem creation logic seems to expect CartItem,
      // but we must adhere to the function signature.
      // We will map the existing SaleItem objects to new ones with the correct saleId and new UUIDs.
      let saleItems = items.map { item in
        SaleItem(
          id: UUID(),
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,  // Retaining productName as per original SaleItem structure
          quantity: item.quantity,
          priceAtSale: item.priceAtSale,
          costAtSale: item.costAtSale  // Retaining costAtSale as per original SaleItem structure
        )
      }

      print("Attempting to create sale items: \(saleItems)")
      try await client.from("sale_items").insert(saleItems).execute()
      print("Sale items created successfully")

      // 3. Update Inventory (Decrement Stock)
      // This part of the snippet expects 'items' to be [CartItem] (e.g., item.product.stockQuantity).
      // Since the function signature is [SaleItem], this logic cannot be directly applied without
      // knowing how to get product details from a SaleItem or if the signature should change.
      // For now, we'll keep the original TODO comment as the inventory decrement logic
      // provided in the snippet is incompatible with the function's current signature.
      // TODO: Decrement inventory - This would require fetching product details for each SaleItem.

      // 4. Update Local Cache
      await fetchSales()

    } catch {
      print("Error creating sale: \(error)")
      errorMessage = "Failed to create sale: \(error.localizedDescription)"
    }
  }
}
