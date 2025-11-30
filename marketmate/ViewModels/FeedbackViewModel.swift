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
final class FeedbackViewModel: ObservableObject {
  @Published var featureRequests: [FeatureRequest] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let client = SupabaseService.shared.client

  func submitBug(description: String) async -> Bool {
    guard let userId = client.auth.currentUser?.id else {
      errorMessage = "User not logged in"
      return false
    }

    isLoading = true
    defer { isLoading = false }

    let bug = Bug(
      user_id: userId,
      description: description,
      status: "open"
    )

    do {
      try await client.from("bugs").insert(bug).execute()
      return true
    } catch {
      errorMessage = "Failed to submit bug: \(error.localizedDescription)"
      return false
    }
  }

  func fetchFeatureRequests() async {
    isLoading = true
    defer { isLoading = false }

    do {
      let features: [FeatureRequest] = try await client
        .from("feature_requests")
        .select()
        .eq("delivered", value: false)
        .order("votes", ascending: false)
        .execute()
        .value

      if let userId = client.auth.currentUser?.id {
        let votes: [FeatureVote] = try await client
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
    } catch {
      errorMessage = "Failed to fetch features: \(error.localizedDescription)"
    }
  }

  func submitFeatureRequest(title: String, description: String) async -> Bool {
    guard let userId = client.auth.currentUser?.id else {
      errorMessage = "User not logged in"
      return false
    }

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
      await fetchFeatureRequests()
      return true
    } catch {
      errorMessage = "Failed to submit feature: \(error.localizedDescription)"
      return false
    }
  }

  func toggleVote(for feature: FeatureRequest) async {
    guard let userId = client.auth.currentUser?.id else {
      errorMessage = "User not logged in"
      return
    }

    if let index = featureRequests.firstIndex(where: { $0.id == feature.id }) {
      let alreadyVoted = featureRequests[index].hasVoted ?? false
      featureRequests[index].hasVoted = !alreadyVoted
      featureRequests[index].votes += alreadyVoted ? -1 : 1
    }

    do {
      let vote = FeatureVote(feature_id: feature.id, user_id: userId)

      if feature.hasVoted == true {
        try await client
          .from("feature_votes")
          .delete()
          .eq("feature_id", value: feature.id)
          .eq("user_id", value: userId)
          .execute()

        try await client.rpc("decrement_votes", params: ["row_id": feature.id]).execute()

      } else {
        try await client.from("feature_votes").insert(vote).execute()

        try await client.rpc("increment_votes", params: ["row_id": feature.id]).execute()
      }

      await fetchFeatureRequests()

    } catch {
      await fetchFeatureRequests()
      errorMessage = "Failed to vote: \(error.localizedDescription)"
    }
  }
}
