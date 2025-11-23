import Foundation

struct Sale: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  var marketId: UUID?
  var totalAmount: Double
  var paymentMethod: String
  var source: String?
  var notes: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case marketId = "market_id"
    case totalAmount = "total_amount"
    case paymentMethod = "payment_method"
    case source
    case notes
    case createdAt = "created_at"
  }
}

struct SaleItem: Codable, Identifiable, Hashable {
  let id: UUID
  let saleId: UUID
  var productId: UUID?
  var productName: String
  var quantity: Int
  var priceAtSale: Double
  var costAtSale: Double?

  enum CodingKeys: String, CodingKey {
    case id
    case saleId = "sale_id"
    case productId = "product_id"
    case productName = "product_name"
    case quantity
    case priceAtSale = "price_at_sale"
    case costAtSale = "cost_at_sale"
  }
}
