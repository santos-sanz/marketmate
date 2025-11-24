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
        .select("*, sale_items(*)")
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
    marketId: UUID?, marketLocation: String?
  ) async {
    print("--- START createSale ---")
    print(
      "Parameters: Total=\(total), Payment=\(paymentMethod), Source=\(source ?? "nil"), Notes=\(notes ?? "nil")"
    )
    print("MarketID=\(marketId?.uuidString ?? "nil"), Location=\(marketLocation ?? "nil")")

    guard let userId = client.auth.currentUser?.id else {
      print("Error: No current user ID found")
      errorMessage = "User not logged in"
      return
    }

    let saleId = UUID()
    print("Generated SaleID: \(saleId)")

    do {
      // 1. Create Sale
      let newSale = Sale(
        id: saleId,
        userId: userId,
        marketId: marketId,
        marketLocation: marketLocation,
        totalAmount: total,
        paymentMethod: paymentMethod,
        source: source,
        notes: notes,
        createdAt: Date()
      )

      print("Preparing to insert Sale object: \(newSale)")
      // Encode to JSON to see exactly what is being sent (for debugging)
      if let jsonData = try? JSONEncoder().encode(newSale),
        let jsonString = String(data: jsonData, encoding: .utf8)
      {
        print("Sale JSON payload: \(jsonString)")
      }

      print("Executing insert on 'sales' table...")
      try await client.from("sales").insert(newSale).execute()
      print("✅ Sale inserted successfully")

      // 2. Create Sale Items
      let saleItems = items.map { item in
        SaleItem(
          id: UUID(),
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          priceAtSale: item.priceAtSale,
          costAtSale: item.costAtSale
        )
      }

      print("Preparing to insert \(saleItems.count) SaleItems")
      if let itemsJsonData = try? JSONEncoder().encode(saleItems),
        let itemsJsonString = String(data: itemsJsonData, encoding: .utf8)
      {
        print("SaleItems JSON payload: \(itemsJsonString)")
      }

      print("Executing insert on 'sale_items' table...")
      try await client.from("sale_items").insert(saleItems).execute()
      print("✅ Sale items inserted successfully")

      // 4. Update Local Cache
      print("Fetching updated sales list...")
      await fetchSales()
      print("--- END createSale (Success) ---")

    } catch {
      print("❌ Error creating sale: \(error)")
      // Dump the error to see more details if available
      dump(error)
      errorMessage = "Failed to create sale: \(error.localizedDescription)"
    }
  }
  func updateSale(_ sale: Sale) async {
    print("Updating sale: \(sale.id)")
    isLoading = true

    do {
      try await client
        .from("sales")
        .update(sale)
        .eq("id", value: sale.id)
        .execute()

      print("✅ Sale updated successfully")
      await fetchSales()
    } catch {
      print("❌ Error updating sale: \(error)")
      errorMessage = "Failed to update sale: \(error.localizedDescription)"
    }
    isLoading = false
  }

  func updateSaleWithItems(_ sale: Sale, updatedItems: [SaleItem], inventoryVM: InventoryViewModel)
    async
  {
    print("🔄 [SalesVM] Updating sale with items: \(sale.id)")
    isLoading = true

    do {
      // 1. Calculate Inventory Changes
      let originalItems = sale.items ?? []

      // Handle Removals and Quantity Changes for existing items
      for originalItem in originalItems {
        if let updatedItem = updatedItems.first(where: { $0.productId == originalItem.productId }) {
          // Item still exists, check quantity diff
          let diff = originalItem.quantity - updatedItem.quantity
          if diff != 0 {
            if let productId = originalItem.productId {
              await inventoryVM.adjustStock(productId: productId, change: diff)
            }
          }
        } else {
          // Item removed, return stock
          if let productId = originalItem.productId {
            await inventoryVM.adjustStock(productId: productId, change: originalItem.quantity)
          }
        }
      }

      // Handle New Items
      for updatedItem in updatedItems {
        if !originalItems.contains(where: { $0.productId == updatedItem.productId }) {
          // New item, deduct stock
          if let productId = updatedItem.productId {
            await inventoryVM.adjustStock(productId: productId, change: -updatedItem.quantity)
          }
        }
      }

      // 2. Update Sale Record (Total Amount, etc)
      try await client
        .from("sales")
        .update(sale)
        .eq("id", value: sale.id)
        .execute()

      // 3. Update Sale Items (Delete all and re-insert)
      // First delete old items
      try await client
        .from("sale_items")
        .delete()
        .eq("sale_id", value: sale.id)
        .execute()

      // Then insert new items
      // Ensure items have the correct saleId
      let itemsToInsert = updatedItems.map { item -> SaleItem in
        var newItem = item
        // We can keep the original ID or generate new ones.
        // Generating new ones is safer for the delete/insert strategy to avoid conflicts if any weird caching.
        // But keeping IDs is better for tracking? Let's generate new IDs for simplicity in this strategy.
        // Actually, let's try to keep IDs if they exist, but for new items generate them.
        // Since we deleted them, we can re-insert with same IDs if we want, but new IDs is safer.
        return SaleItem(
          id: UUID(),
          saleId: sale.id,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          priceAtSale: item.priceAtSale,
          costAtSale: item.costAtSale
        )
      }

      try await client
        .from("sale_items")
        .insert(itemsToInsert)
        .execute()

      print("✅ [SalesVM] Sale and items updated successfully")
      await fetchSales()

    } catch {
      print("❌ [SalesVM] Error updating sale with items: \(error)")
      errorMessage = "Failed to update sale: \(error.localizedDescription)"
    }
    isLoading = false
  }
}
