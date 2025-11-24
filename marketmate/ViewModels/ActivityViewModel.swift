import Combine
import Foundation
import Supabase
import SwiftUI

@MainActor
class ActivityViewModel: ObservableObject {
  @Published var activities: [Activity] = []
  @Published var filteredActivities: [Activity] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var expandedDetails: ActivityDetail?
  @Published var isLoadingDetails = false

  private let client = SupabaseService.shared.client

  enum ActivityDetail {
    case sale(Sale)
    case cost(Cost)
    case product(Product)
    case market(Market)
  }

  enum ActivityFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case sales = "Sales"
    case costs = "Expenses"
    case products = "Products"
    case market = "Market"

    var id: String { rawValue }
  }

  enum DateFilter: String, CaseIterable, Identifiable {
    case allTime = "All Time"
    case today = "Today"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"

    var id: String { rawValue }
  }

  @Published var selectedFilter: ActivityFilter = .all { didSet { applyFilter() } }
  @Published var selectedDateFilter: DateFilter = .allTime { didSet { applyFilter() } }
  @Published var searchText: String = "" { didSet { applyFilter() } }
  func fetchActivities() async {
    guard let userId = client.auth.currentUser?.id else { return }

    isLoading = true
    errorMessage = nil

    do {
      let fetchedActivities: [Activity] =
        try await client
        .from("recent_activity")
        .select()
        .eq("user_id", value: userId)
        .order("created_at", ascending: false)
        .limit(100)  // Fetch more for history view
        .execute()
        .value

      self.activities = fetchedActivities
      applyFilter()
      print("✅ [ActivityViewModel] Fetched \(fetchedActivities.count) activities")
    } catch {
      print("❌ [ActivityViewModel] Error fetching activities: \(error)")
      self.errorMessage = "Failed to load activities"
    }

    isLoading = false
  }

  private func applyFilter() {
    var result = activities

    // 1. Category Filter
    switch selectedFilter {
    case .all:
      break
    case .sales:
      result = result.filter { $0.type == .sale }
    case .costs:
      result = result.filter { $0.type == .cost }
    case .products:
      result = result.filter {
        [.productCreated, .productUpdated, .productDeleted].contains($0.type)
      }
    case .market:
      result = result.filter {
        [.marketOpened, .marketClosed].contains($0.type)
      }
    }

    // 2. Date Filter
    let calendar = Calendar.current
    let now = Date()
    switch selectedDateFilter {
    case .allTime:
      break
    case .today:
      result = result.filter { calendar.isDateInToday($0.createdAt) }
    case .last7Days:
      if let date = calendar.date(byAdding: .day, value: -7, to: now) {
        result = result.filter { $0.createdAt >= date }
      }
    case .last30Days:
      if let date = calendar.date(byAdding: .day, value: -30, to: now) {
        result = result.filter { $0.createdAt >= date }
      }
    }

    // 3. Search Filter
    if !searchText.isEmpty {
      result = result.filter { activity in
        activity.title.localizedCaseInsensitiveContains(searchText)
          || (activity.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false)
      }
    }

    filteredActivities = result
  }

  func fetchDetails(for activity: Activity) async {
    isLoadingDetails = true
    expandedDetails = nil

    do {
      switch activity.type {
      case .sale:
        let sale: Sale =
          try await client
          .from("sales")
          .select("*, sale_items(*)")  // Fetch items relation
          .eq("id", value: activity.id)
          .single()
          .execute()
          .value
        expandedDetails = .sale(sale)

      case .cost:
        let cost: Cost =
          try await client
          .from("costs")
          .select()
          .eq("id", value: activity.id)
          .single()
          .execute()
          .value
        expandedDetails = .cost(cost)

      case .productCreated, .productUpdated, .productDeleted:
        let product: Product =
          try await client
          .from("products")
          .select()
          .eq("id", value: activity.id)
          .single()
          .execute()
          .value
        expandedDetails = .product(product)

      case .marketOpened, .marketClosed:
        // Assuming activity.id is the market_id for these events
        // If not, we might need to check if there's a separate market_id field in Activity
        // But based on typical pattern, the ID usually points to the entity.
        let market: Market =
          try await client
          .from("markets")
          .select()
          .eq("id", value: activity.id)
          .single()
          .execute()
          .value
        expandedDetails = .market(market)

      default:
        break
      }
    } catch {
      print("❌ [ActivityViewModel] Error fetching details: \(error)")
    }

    isLoadingDetails = false
  }
  // Helper to group activities by date
  func groupedActivities() -> [(key: String, value: [Activity])] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: filteredActivities) { (activity) -> String in
      if calendar.isDateInToday(activity.createdAt) {
        return "Today"
      } else if calendar.isDateInYesterday(activity.createdAt) {
        return "Yesterday"
      } else {
        return activity.createdAt.formatted(date: .long, time: .omitted)
      }
    }

    // Sort keys to maintain order (Today, Yesterday, then dates descending)
    let sortedKeys = grouped.keys.sorted { (dateString1, dateString2) -> Bool in
      if dateString1 == "Today" { return true }
      if dateString2 == "Today" { return false }
      if dateString1 == "Yesterday" { return true }
      if dateString2 == "Yesterday" { return false }

      // Parse dates for comparison if needed, or rely on activity order if consistent
      // Since we want reverse chronological, and the list is already sorted,
      // we can rely on the first item of each group to sort the groups.
      guard let first1 = grouped[dateString1]?.first, let first2 = grouped[dateString2]?.first
      else { return false }
      return first1.createdAt > first2.createdAt
    }

    return sortedKeys.map { (key: $0, value: grouped[$0] ?? []) }
  }
}
