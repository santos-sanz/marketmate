import Foundation

struct Product: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  var name: String
  var description: String?
  var price: Double
  var cost: Double?
  var stockQuantity: Int?
  var categoryId: UUID?
  var imageUrl: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case name
    case description
    case price
    case cost
    case stockQuantity = "stock_quantity"
    case categoryId = "category_id"
    case imageUrl = "image_url"
    case createdAt = "created_at"
  }
}

struct ProductVariant: Codable, Identifiable, Hashable {
  let id: UUID
  let productId: UUID
  var name: String
  var price: Double?
  var stockQuantity: Int
  var sku: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case productId = "product_id"
    case name
    case price
    case stockQuantity = "stock_quantity"
    case sku
    case createdAt = "created_at"
  }
}
