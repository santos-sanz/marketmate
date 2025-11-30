import Foundation

struct Activity: Identifiable, Codable {
  let id: UUID
  let userId: UUID
  let type: ActivityType
  let title: String
  let subtitle: String?
  let amount: Double?
  let quantity: Int?
  let createdAt: Date

  enum ActivityType: String, Codable {
    case sale
    case cost
    case productCreated = "product_created"
    case productUpdated = "product_updated"
    case productDeleted = "product_deleted"
    case marketOpened = "market_opened"
    case marketClosed = "market_closed"
  }

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case type
    case title
    case subtitle
    case amount
    case quantity
    case createdAt = "created_at"
  }
}

extension Activity {
  var isProductActivity: Bool {
    [.productCreated, .productUpdated, .productDeleted].contains(type)
  }
}
