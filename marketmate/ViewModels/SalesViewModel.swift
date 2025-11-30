import Combine
import Foundation
import Supabase

struct CartItem: Identifiable {
  let id = UUID()
  let product: Product?
  var name: String
  var price: Double
  var quantity: Int
}

@MainActor
final class SalesViewModel: ObservableObject {
  @Published var sales: [Sale] = []
  @Published var cartItems: [CartItem] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  var cartTotal: Double {
    cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
  }

  func quantityInCart(for product: Product) -> Int {
    cartItems.first(where: { $0.product?.id == product.id })?.quantity ?? 0
  }

  func addToCart(product: Product) {
    if let index = cartItems.firstIndex(where: { $0.product?.id == product.id }) {
      cartItems[index].quantity += 1
    } else {
      cartItems.append(
        CartItem(product: product, name: product.name, price: product.price, quantity: 1))
    }
  }

  func addCustomAmount(name: String, price: Double) {
    cartItems.append(CartItem(product: nil, name: name, price: price, quantity: 1))
  }

  func removeFromCart(item: CartItem) {
    if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
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
      let sales: [Sale] = try await client
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
    guard let userId = client.auth.currentUser?.id else {
      errorMessage = "User not logged in"
      return
    }

    let saleId = UUID()

    do {
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

      try await client.from("sales").insert(newSale).execute()

      let saleItems = items.map { item -> SaleItem in
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

      try await client.from("sale_items").insert(saleItems).execute()
      await fetchSales()
    } catch {
      errorMessage = "Failed to create sale: \(error.localizedDescription)"
    }
  }

  func updateSale(_ sale: Sale) async {
    isLoading = true
    defer { isLoading = false }

    do {
      try await client
        .from("sales")
        .update(sale)
        .eq("id", value: sale.id)
        .execute()
      await fetchSales()
    } catch {
      errorMessage = "Failed to update sale: \(error.localizedDescription)"
    }
  }

  func updateSaleWithItems(_ sale: Sale, updatedItems: [SaleItem], inventoryVM: InventoryViewModel)
    async
  {
    isLoading = true
    defer { isLoading = false }

    do {
      let originalItems = sale.items ?? []

      for originalItem in originalItems {
        if let updatedItem = updatedItems.first(where: { $0.productId == originalItem.productId }) {
          let diff = originalItem.quantity - updatedItem.quantity
          if diff != 0, let productId = originalItem.productId {
            await inventoryVM.adjustStock(productId: productId, change: diff)
          }
        } else {
          if let productId = originalItem.productId {
            await inventoryVM.adjustStock(productId: productId, change: originalItem.quantity)
          }
        }
      }

      for updatedItem in updatedItems {
        if !originalItems.contains(where: { $0.productId == updatedItem.productId }) {
          if let productId = updatedItem.productId {
            await inventoryVM.adjustStock(productId: productId, change: -updatedItem.quantity)
          }
        }
      }

      try await client
        .from("sales")
        .update(sale)
        .eq("id", value: sale.id)
        .execute()

      try await client
        .from("sale_items")
        .delete()
        .eq("sale_id", value: sale.id)
        .execute()

      let itemsToInsert = updatedItems.map { item -> SaleItem in
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

      await fetchSales()

    } catch {
      errorMessage = "Failed to update sale: \(error.localizedDescription)"
    }
  }
}
