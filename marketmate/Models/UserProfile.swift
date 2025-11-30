import Foundation

struct UserProfile: Codable, Identifiable {
  let id: UUID
  var username: String?
  var fullName: String?
  var avatarUrl: String?
  var website: String?
  var currency: String?
  var useInventory: Bool?
  let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case username
    case fullName = "full_name"
    case avatarUrl = "avatar_url"
    case website
    case currency
    case useInventory = "use_inventory"
    case updatedAt = "updated_at"
  }
}
