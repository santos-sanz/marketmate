import Foundation
import Supabase

enum ActivityService {
  static func fetchRecent(limit: Int = 20) async throws -> [Activity] {
    let client = SupabaseService.shared.client
    guard let userId = client.auth.currentUser?.id else {
      throw ActivityServiceError.missingUser
    }

    return try await client
      .from("recent_activity")
      .select()
      .eq("user_id", value: userId)
      .order("created_at", ascending: false)
      .limit(limit)
      .execute()
      .value
  }
}

enum ActivityServiceError: LocalizedError {
  case missingUser

  var errorDescription: String? {
    switch self {
    case .missingUser:
      return "No authenticated user found."
    }
  }
}
