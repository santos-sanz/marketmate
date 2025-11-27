import Foundation

enum CategoryType: String, Codable {
  case inventory
  case cost
}

struct Category: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  var name: String
  var type: CategoryType
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case name
    case type
    case createdAt = "created_at"
  }
}
