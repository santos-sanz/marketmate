import Supabase
import SwiftUI

struct HomeView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel

  // For navigation
  @State private var showingAddSale = false
  @State private var showingAddCost = false

  // Navigation States
  @State private var navigateToProfile = false
  @State private var navigateToReports = false

  // Activities
  @State private var activities: [Activity] = []
  private let client = SupabaseService.shared.client

  // Time Interval Enum
  enum TimeInterval: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case allTime = "All Time"
  }

  @State private var selectedInterval: TimeInterval = .daily

  var filteredSales: [Sale] {
    filterByDate(salesVM.sales, dateKey: \.createdAt)
  }

  var filteredCosts: [Cost] {
    filterByDate(costsVM.costs, dateKey: \.createdAt)
  }

  var totalBalance: Double {
    let salesTotal = filteredSales.reduce(0) { $0 + $1.totalAmount }
    let costsTotal = filteredCosts.reduce(0) { $0 + $1.amount }
    return salesTotal - costsTotal
  }

  func filterByDate<T>(_ items: [T], dateKey: KeyPath<T, Date>) -> [T] {
    let calendar = Calendar.current
    let now = Date()
    return items.filter { item in
      let date = item[keyPath: dateKey]
      switch selectedInterval {
      case .daily:
        return calendar.isDateInToday(date)
      case .weekly:
        return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
      case .monthly:
        return calendar.isDate(date, equalTo: now, toGranularity: .month)
      case .allTime:
        return true
      }
    }
  }

  @State private var selectedTransaction: TransactionWrapper?
  @State private var searchText = ""

  var body: some View {
    NavigationStack {
      ZStack {
        // Blue Gradient Background
        Color.clear.revolutBackground()

        VStack(spacing: 24) {
          // Header (Profile, Search, Reports)
          HStack(spacing: 12) {
            Button(action: { navigateToProfile = true }) {
              Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.white.opacity(0.8))
            }

            // Search Bar
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.8))  // Increased contrast
              TextField("", text: $searchText)
                .foregroundColor(.white)
                .accentColor(.white)
                .placeholder(when: searchText.isEmpty) {
                  Text("Search").foregroundColor(Color.white.opacity(0.6))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.1))  // Darkened for better contrast with white icon
            .cornerRadius(20)

            Button(action: { navigateToReports = true }) {
              Image(systemName: "chart.bar.xaxis")
                .foregroundColor(.white)
                .font(Typography.title3)
            }
          }
          .padding(.horizontal, Spacing.md)
          .padding(.top, 10)

          // Total Balance (Only show if not searching)
          if searchText.isEmpty {
            VStack(spacing: 8) {
              // Dropdown Menu for Time Interval
              Menu {
                Picker("Time Interval", selection: $selectedInterval) {
                  ForEach(TimeInterval.allCases, id: \.self) { interval in
                    Text(interval.rawValue).tag(interval)
                  }
                }
              } label: {
                HStack(spacing: 4) {
                  Text("Total Balance \(selectedInterval.rawValue)")
                    .font(Typography.subheadline)
                    .foregroundColor(.marketTextSecondary)
                  Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.marketTextSecondary)
                }
              }

              Text("\(profileVM.currencySymbol) \(String(format: "%.2f", totalBalance))")
                .font(Typography.display)
                .foregroundColor(.white)
            }

            // Action Buttons
            HStack(spacing: 30) {
              ActionButton(icon: "tag.fill", label: "Add Sale") {  // Consistent Icon
                showingAddSale = true
              }

              ActionButton(icon: "arrow.down.circle.fill", label: "Add Cost") {  // Consistent Icon
                showingAddCost = true
              }

              ActionButton(icon: "list.bullet", label: "Details") {
                navigateToReports = true
              }

            }
            .padding(.horizontal, Spacing.md)
          }

          // Recent Transactions (List)
          VStack(alignment: .leading) {
            Text("Recent Activity")
              .font(.headline)
              .foregroundColor(.white)
              .padding(.horizontal)

            ScrollView {
              VStack(spacing: 0) {
                let filteredActivities =
                  searchText.isEmpty
                  ? activities
                  : activities.filter {
                    $0.title.localizedCaseInsensitiveContains(searchText)
                      || ($0.subtitle ?? "").localizedCaseInsensitiveContains(searchText)
                  }

                ForEach(filteredActivities.prefix(5)) { activity in
                  ActivityRow(
                    activity: activity,
                    currency: profileVM.currencySymbol
                  )

                  if activity.id != filteredActivities.prefix(5).last?.id {
                    Divider()
                      .background(Color.white.opacity(0.1))
                      .padding(.leading, 50)
                  }
                }

                // See All Button
                NavigationLink(destination: ActivityHistoryView()) {
                  Text("See all")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
              }
              .background(Color.marketCard)
              .cornerRadius(16)
              .padding(.horizontal)
            }
          }

          Spacer()
        }
      }
      .navigationDestination(isPresented: $navigateToProfile) {
        ProfileView()
      }
      .navigationDestination(isPresented: $navigateToReports) {
        ReportsView()
      }
      .navigationDestination(isPresented: $showingAddSale) {
        SalesView()
          .environmentObject(salesVM)
          .environmentObject(costsVM)
          .environmentObject(inventoryVM)
      }
      .navigationDestination(isPresented: $showingAddCost) {
        AddCostView()
      }
      .navigationDestination(for: TransactionWrapper.self) { transaction in
        if let sale = transaction.originalSale {
          SaleDetailView(sale: sale)
            .environmentObject(salesVM)
            .environmentObject(profileVM)
        } else if let cost = transaction.originalCost {
          CostDetailView(cost: cost)
            .environmentObject(costsVM)
            .environmentObject(profileVM)
        } else if let product = transaction.originalProduct {
          ProductDetailView(product: product)
            .environmentObject(inventoryVM)
        }
      }
      .navigationBarHidden(true)
    }
    .onAppear {
      Task {
        await fetchActivities()
        await salesVM.fetchSales()
        await costsVM.fetchCosts()
      }
    }
  }

  func fetchActivities() async {
    guard let userId = client.auth.currentUser?.id else { return }

    do {
      let fetchedActivities: [Activity] =
        try await client
        .from("recent_activity")
        .select()
        .eq("user_id", value: userId)
        .order("created_at", ascending: false)
        .limit(50)
        .execute()
        .value

      self.activities = fetchedActivities
      print("✅ [HomeView] Fetched \(fetchedActivities.count) activities")

      // Debug: Print market events with their subtitles
      let marketEvents = fetchedActivities.filter {
        $0.type == .marketOpened || $0.type == .marketClosed
      }
      for event in marketEvents.prefix(5) {
        print(
          "🔍 [HomeView] \(event.type.rawValue): \(event.title) - subtitle: '\(event.subtitle ?? "nil")'"
        )
      }
    } catch {
      print("❌ [HomeView] Error fetching activities: \(error)")
    }
  }
}

struct ActionButton: View {
  let icon: String
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Circle()
          .fill(Color.white.opacity(0.2))
          .frame(width: 50, height: 50)
          .overlay(
            Image(systemName: icon)
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(.white)
          )

        Text(label)
          .font(.caption)
          .foregroundColor(.white)
      }
    }
  }
}

struct ActivityRow: View {
  let activity: Activity
  let currency: String

  var iconName: String {
    switch activity.type {
    case .sale: return "tag.fill"
    case .cost: return "arrow.down.circle.fill"
    case .productCreated, .productUpdated, .productDeleted: return "cube.box.fill"
    case .marketOpened: return "tent.fill"
    case .marketClosed: return "tent"
    }
  }

  var iconColor: Color {
    switch activity.type {
    case .sale: return .marketGreen
    case .cost: return .red
    case .productCreated, .productUpdated, .productDeleted: return .marketBlue
    case .marketOpened, .marketClosed: return .yellow
    }
  }

  var backgroundColor: Color {
    switch activity.type {
    case .sale: return Color.marketGreen.opacity(0.2)
    case .cost: return Color.red.opacity(0.2)
    case .productCreated, .productUpdated, .productDeleted: return Color.marketBlue.opacity(0.2)
    case .marketOpened, .marketClosed: return Color.yellow.opacity(0.2)
    }
  }

  var body: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(backgroundColor)
        .frame(width: 28, height: 28)
        .overlay(
          Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(.system(size: 12, weight: .bold))
        )

      VStack(alignment: .leading, spacing: 1) {
        Text(activity.title)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.white)

        if let subtitle = activity.subtitle {
          Text(subtitle)
            .font(.caption2)
            .foregroundColor(.marketTextSecondary)
            .lineLimit(1)
        }
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 1) {
        // Show quantity for products, amount for sales/costs
        if let qty = activity.quantity {
          Text("\(qty > 0 ? "+" : "")\(qty)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
        } else if let amount = activity.amount {
          let isPositive = activity.type == .sale
          Text("\(isPositive ? "+" : "-")\(currency)\(String(format: "%.2f", amount))")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
        }

        Text(activity.createdAt.formatted(date: .abbreviated, time: .shortened))
          .font(.caption2)
          .foregroundColor(.marketTextSecondary)
      }
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
    .contentShape(Rectangle())
  }
}

struct TransactionRow: View {
  let title: String
  let subtitle: String
  let amount: Double
  let isPositive: Bool
  let currency: String
  let date: Date
  var location: String? = nil
  var quantity: Int? = nil  // For products

  var iconName: String {
    if isPositive { return "tag.fill" }
    if amount == 0 { return "cube.box.fill" }  // Product
    return "arrow.down.circle.fill"  // Cost
  }

  var iconColor: Color {
    if isPositive { return .marketGreen }
    if amount == 0 { return .marketBlue }  // Product
    return .red  // Cost
  }

  var backgroundColor: Color {
    if isPositive { return Color.marketGreen.opacity(0.2) }
    if amount == 0 { return Color.marketBlue.opacity(0.2) }  // Product
    return Color.red.opacity(0.2)  // Cost
  }

  var body: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(backgroundColor)
        .frame(width: 28, height: 28)
        .overlay(
          Image(systemName: iconName)
            .foregroundColor(iconColor)
            .font(.system(size: 12, weight: .bold))
        )

      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.white)

        Text(subtitle)
          .font(.caption2)
          .foregroundColor(.marketTextSecondary)
          .lineLimit(1)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 1) {
        // Show quantity for products, amount for sales/costs
        if let qty = quantity {
          Text("\(qty > 0 ? "+" : "")\(qty)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
        } else {
          Text("\(isPositive ? "+" : "-")\(currency)\(String(format: "%.2f", amount))")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
        }

        Text(date.formatted(date: .abbreviated, time: .shortened))
          .font(.caption2)
          .foregroundColor(.marketTextSecondary)
      }
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 12)
    .contentShape(Rectangle())  // Make the whole row tappable
  }
}

struct TransactionWrapper: Identifiable, Hashable {
  let id = UUID()
  let title: String
  let subtitle: String
  let amount: Double
  let isPositive: Bool
  let date: Date
  var location: String? = nil
  var quantity: Int? = nil  // For products

  // Keep references to original objects for detail view
  let originalSale: Sale?
  let originalCost: Cost?
  let originalProduct: Product?

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: TransactionWrapper, rhs: TransactionWrapper) -> Bool {
    lhs.id == rhs.id
  }

  init(sale: Sale) {
    self.title = sale.paymentMethod  // Use payment method as title
    if let items = sale.items {
      self.subtitle = items.map { "\($0.quantity)x \($0.productName)" }.joined(separator: ", ")
    } else {
      self.subtitle = "Sale"
    }
    self.amount = sale.totalAmount
    self.isPositive = true
    self.date = sale.createdAt
    self.location = sale.marketLocation
    self.quantity = nil
    self.originalSale = sale
    self.originalCost = nil
    self.originalProduct = nil
  }

  init(cost: Cost) {
    self.title = cost.description
    self.subtitle = cost.category ?? "Expense"
    self.amount = cost.amount
    self.isPositive = false
    self.date = cost.createdAt
    self.location = nil
    self.quantity = nil
    self.originalSale = nil
    self.originalCost = cost
    self.originalProduct = nil
  }

  init(product: Product) {
    self.title = product.name
    self.subtitle = "Product added"
    self.amount = 0  // Set to 0 to trigger neutral icon
    self.isPositive = false  // Neutral, not a sale or cost
    self.date = product.createdAt
    self.location = nil
    self.quantity = product.stockQuantity ?? 0  // Show stock quantity
    self.originalSale = nil
    self.originalCost = nil
    self.originalProduct = product
  }
}
