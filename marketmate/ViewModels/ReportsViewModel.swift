import Combine
import Foundation
import Supabase

enum TimeRange: String, CaseIterable {
  case day = "Day"
  case week = "Week"
  case month = "Month"
  case year = "Year"
}

@MainActor
class ReportsViewModel: ObservableObject {
  @Published var totalSales: Double = 0
  @Published var totalCosts: Double = 0
  @Published var netProfit: Double = 0
  @Published var salesData: [DailySales] = []
  @Published var isLoading = false
  @Published var selectedTimeRange: TimeRange = .month

  private let client = SupabaseService.shared.client

  struct DailySales: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
  }

  func fetchData() async {
    isLoading = true

    // Calculate start date based on selectedTimeRange
    let calendar = Calendar.current
    let now = Date()
    var startDate: Date

    switch selectedTimeRange {
    case .day:
      startDate = calendar.startOfDay(for: now)
    case .week:
      startDate = calendar.date(byAdding: .day, value: -7, to: now)!
    case .month:
      startDate = calendar.date(byAdding: .month, value: -1, to: now)!
    case .year:
      startDate = calendar.date(byAdding: .year, value: -1, to: now)!
    }

    // Format date for Supabase query (ISO8601)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let startDateString = formatter.string(from: startDate)

    do {
      // Fetch Sales
      let sales: [Sale] =
        try await client
        .from("sales")
        .select()
        .gte("created_at", value: startDateString)
        .execute()
        .value

      // Fetch Costs
      let costs: [Cost] =
        try await client
        .from("costs")
        .select()
        .gte("created_at", value: startDateString)
        .execute()
        .value

      self.totalSales = sales.reduce(0) { $0 + $1.totalAmount }
      self.totalCosts = costs.reduce(0) { $0 + $1.amount }
      self.netProfit = totalSales - totalCosts

      // Group sales by date for the chart
      let groupedSales = Dictionary(grouping: sales) { sale -> Date in
        let components = calendar.dateComponents([.year, .month, .day], from: sale.createdAt)
        return calendar.date(from: components) ?? sale.createdAt
      }

      self.salesData = groupedSales.map { (date, sales) in
        DailySales(date: date, amount: sales.reduce(0) { $0 + $1.totalAmount })
      }.sorted { $0.date < $1.date }

    } catch {
      print("Error fetching reports data: \(error)")
    }

    isLoading = false
  }
}
