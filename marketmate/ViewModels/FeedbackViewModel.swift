import Combine
import Foundation
import Supabase

struct Bug: Encodable, Decodable {
  var id: UUID?
  var user_id: UUID
  var description: String
  var status: String
  var created_at: Date?
}

struct FeatureRequest: Identifiable, Encodable, Decodable {
  var id: UUID
  var user_id: UUID
  var title: String
  var description: String
  var votes: Int
  var delivered: Bool
  var created_at: Date

  // For UI state, not in DB
  var hasVoted: Bool?
}

struct FeatureVote: Encodable, Decodable {
  var feature_id: UUID
  var user_id: UUID
}

@MainActor
class FeedbackViewModel: ObservableObject {
  @Published var featureRequests: [FeatureRequest] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  func submitBug(description: String) async -> Bool {
    guard let userId = client.auth.currentUser?.id else {
      print("❌ [FeedbackVM] No user ID found for bug submission")
      return false
    }
    print("🐞 [FeedbackVM] Submitting bug report...")

    isLoading = true
    defer { isLoading = false }

    let bug = Bug(
      user_id: userId,
      description: description,
      status: "open"
    )

    do {
      try await client.from("bugs").insert(bug).execute()
      print("✅ [FeedbackVM] Bug submitted successfully")
      return true
    } catch {
      errorMessage = "Failed to submit bug: \(error.localizedDescription)"
      print("❌ [FeedbackVM] Error submitting bug: \(error)")
      return false
    }
  }

  func fetchFeatureRequests() async {
    print("💡 [FeedbackVM] Fetching feature requests...")
    isLoading = true
    defer { isLoading = false }

    do {
      // Fetch features
      let features: [FeatureRequest] =
        try await client
        .from("feature_requests")
        .select()
        .eq("delivered", value: false)
        .order("votes", ascending: false)
        .execute()
        .value

      // Fetch user votes to mark "hasVoted"
      if let userId = client.auth.currentUser?.id {
        let votes: [FeatureVote] =
          try await client
          .from("feature_votes")
          .select()
          .eq("user_id", value: userId)
          .execute()
          .value

        let votedFeatureIds = Set(votes.map { $0.feature_id })

        self.featureRequests = features.map { feature in
          var f = feature
          f.hasVoted = votedFeatureIds.contains(feature.id)
          return f
        }
      } else {
        self.featureRequests = features
      }
      print("✅ [FeedbackVM] Fetched \(features.count) feature requests")
    } catch {
      errorMessage = "Failed to fetch features: \(error.localizedDescription)"
      print("❌ [FeedbackVM] Error fetching feature requests: \(error)")
    }
  }

  func submitFeatureRequest(title: String, description: String) async -> Bool {
    guard let userId = client.auth.currentUser?.id else {
      print("❌ [FeedbackVM] No user ID found for feature submission")
      return false
    }
    print("💡 [FeedbackVM] Submitting feature request: \(title)")

    isLoading = true
    defer { isLoading = false }

    let feature = FeatureRequest(
      id: UUID(),
      user_id: userId,
      title: title,
      description: description,
      votes: 0,
      delivered: false,
      created_at: Date()
    )

    do {
      try await client.from("feature_requests").insert(feature).execute()
      print("✅ [FeedbackVM] Feature request submitted successfully")
      await fetchFeatureRequests()  // Refresh list
      return true
    } catch {
      errorMessage = "Failed to submit feature: \(error.localizedDescription)"
      print("❌ [FeedbackVM] Error submitting feature request: \(error)")
      return false
    }
  }

  func toggleVote(for feature: FeatureRequest) async {
    guard let userId = client.auth.currentUser?.id else {
      print("❌ [FeedbackVM] No user ID found for voting")
      return
    }
    print("💡 [FeedbackVM] Toggling vote for feature: \(feature.title)")

    // Optimistic update
    if let index = featureRequests.firstIndex(where: { $0.id == feature.id }) {
      let alreadyVoted = featureRequests[index].hasVoted ?? false
      featureRequests[index].hasVoted = !alreadyVoted
      featureRequests[index].votes += alreadyVoted ? -1 : 1
    }

    do {
      let vote = FeatureVote(feature_id: feature.id, user_id: userId)

      if feature.hasVoted == true {
        // Remove vote (delete)
        try await client
          .from("feature_votes")
          .delete()
          .eq("feature_id", value: feature.id)
          .eq("user_id", value: userId)
          .execute()

        // Decrement count in feature_requests
        try await client.rpc("decrement_votes", params: ["row_id": feature.id]).execute()

      } else {
        // Add vote
        try await client.from("feature_votes").insert(vote).execute()

        // Increment count
        try await client.rpc("increment_votes", params: ["row_id": feature.id]).execute()
      }

      // We could refetch, but optimistic update is smoother.
      // Ideally we use an RPC to increment/decrement to be safe, but for now simple update is okay or just refetch.
      // Actually, without RPC, concurrent updates to 'votes' column are race-condition prone.
      // But for this MVP, I'll just refetch to be sure.
      print("✅ [FeedbackVM] Vote toggled successfully")
      await fetchFeatureRequests()

    } catch {
      // Revert on error
      print("❌ [FeedbackVM] Error toggling vote: \(error)")
      await fetchFeatureRequests()
      errorMessage = "Failed to vote: \(error.localizedDescription)"
    }
  }
}
