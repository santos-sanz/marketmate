import Foundation

struct CostCategory: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  var name: String
  var color: String?
  var icon: String?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case name
    case color
    case icon
    case createdAt = "created_at"
  }
}

struct Cost: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  var marketId: UUID?
  var description: String
  var amount: Double
  var category: String?
  var isRecurrent: Bool?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case marketId = "market_id"
    case description
    case amount
    case category
    case isRecurrent = "is_recurrent"
    case createdAt = "created_at"
  }
}
