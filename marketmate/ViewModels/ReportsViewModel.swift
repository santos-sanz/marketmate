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
  @Published var salesCount: Int = 0
  @Published var averageTicket: Double = 0
  @Published var profitMargin: Double = 0
  @Published var averageDailySales: Double = 0
  @Published var paymentBreakdown: [Breakdown] = []
  @Published var locationBreakdown: [Breakdown] = []
  @Published var bestDay: DailySales?
  @Published var isLoading = false
  @Published var selectedTimeRange: TimeRange = .month

  private let client = SupabaseService.shared.client

  struct DailySales: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
  }

  struct Breakdown: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let percentage: Double
  }

  func fetchData() async {
    print("📊 [ReportsVM] Fetching reports data for \(selectedTimeRange.rawValue)...")
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

      self.salesCount = sales.count
      self.totalSales = sales.reduce(0) { $0 + $1.totalAmount }
      self.totalCosts = costs.reduce(0) { $0 + $1.amount }
      self.netProfit = totalSales - totalCosts
      self.averageTicket = salesCount > 0 ? totalSales / Double(salesCount) : 0
      self.profitMargin = totalSales > 0 ? netProfit / totalSales : 0

      print(
        "📊 [ReportsVM] Fetched \(sales.count) sales, \(costs.count) costs. Total: $\(totalSales), Net: $\(netProfit)"
      )

      // Group sales by date for the chart
      let groupedSales = Dictionary(grouping: sales) { sale -> Date in
        let components = calendar.dateComponents([.year, .month, .day], from: sale.createdAt)
        return calendar.date(from: components) ?? sale.createdAt
      }

      self.salesData =
        groupedSales.map { (date, sales) in
          DailySales(date: date, amount: sales.reduce(0) { $0 + $1.totalAmount })
        }.sorted { $0.date < $1.date }

      // KPI helpers
      let daySpan = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
      self.averageDailySales =
        totalSales / Double(max(1, daySpan + 1))
      self.bestDay = salesData.max(by: { $0.amount < $1.amount })

      // Payment method breakdown
      let paymentTotals = Dictionary(grouping: sales, by: { $0.paymentMethod }).map {
        method, sales -> Breakdown in
        let value = sales.reduce(0) { $0 + $1.totalAmount }
        let percentage = totalSales > 0 ? value / totalSales : 0
        return Breakdown(label: method, value: value, percentage: percentage)
      }
      .sorted { $0.value > $1.value }
      self.paymentBreakdown = paymentTotals

      // Location breakdown (market level pulse)
      // Location breakdown (market level pulse)
      let salesWithLocation = sales.filter {
        guard
          let location = $0.marketLocation?.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines), !location.isEmpty
        else { return false }
        return true
      }

      let locationTotals = Dictionary(grouping: salesWithLocation) { sale -> String in
        return sale.marketLocation!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      }.map { location, sales -> Breakdown in
        let value = sales.reduce(0) { $0 + $1.totalAmount }
        let percentage = totalSales > 0 ? value / totalSales : 0
        return Breakdown(label: location, value: value, percentage: percentage)
      }
      .sorted { $0.value > $1.value }
      self.locationBreakdown = locationTotals

    } catch {
      print("❌ [ReportsVM] Error fetching reports data: \(error)")
    }

    isLoading = false
  }
}
