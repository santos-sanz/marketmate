import Foundation

struct Market: Codable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  var name: String
  var location: String?
  var latitude: Double?
  var longitude: Double?
  var date: Date
  var isOpen: Bool
  var endTime: Date?
  let createdAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case name
    case location
    case latitude
    case longitude
    case date
    case isOpen = "is_open"
    case endTime = "end_time"
    case createdAt = "created_at"
  }
}
