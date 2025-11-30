import SwiftUI

struct HomeView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel

  @State private var showingAddSale = false
  @State private var showingAddCost = false
  @State private var navigateToProfile = false
  @State private var navigateToReports = false
  @State private var activities: [Activity] = []
  @State private var searchText = ""
  @State private var selectedInterval: TimeInterval = .daily

  enum TimeInterval: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case allTime = "All Time"
  }

  private var filteredSales: [Sale] {
    filterByDate(salesVM.sales, dateKey: \.createdAt)
  }

  private var filteredCosts: [Cost] {
    filterByDate(costsVM.costs, dateKey: \.createdAt)
  }

  private var totalBalance: Double {
    let salesTotal = filteredSales.reduce(0) { $0 + $1.totalAmount }
    let costsTotal = filteredCosts.reduce(0) { $0 + $1.amount }
    return salesTotal - costsTotal
  }

  private var filteredActivities: [Activity] {
    guard !searchText.isEmpty else { return activities }
    return activities.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || ($0.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
  }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      VStack(spacing: 24) {
        header
        if searchText.isEmpty { balanceSection }
        recentActivitySection
        Spacer()
      }
    }
    .navigationDestination(isPresented: $navigateToProfile) { ProfileView() }
    .navigationDestination(isPresented: $navigateToReports) { ReportsView() }
    .navigationDestination(isPresented: $showingAddSale) {
      SalesView()
        .environmentObject(salesVM)
        .environmentObject(costsVM)
        .environmentObject(inventoryVM)
    }
    .navigationDestination(isPresented: $showingAddCost) { AddCostView() }
    .navigationBarHidden(true)
    .onAppear { Task { await loadData() } }
  }

  private var header: some View {
    HStack(spacing: 12) {
      Button(action: { navigateToProfile = true }) {
        Image(systemName: "person.crop.circle.fill")
          .resizable()
          .frame(width: 40, height: 40)
          .foregroundColor(.marketTextSecondary)
      }

      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.marketTextSecondary)
        TextField("", text: $searchText)
          .foregroundColor(.white)
          .accentColor(.white)
          .placeholder(when: searchText.isEmpty) {
            Text("Search").foregroundColor(.marketTextSecondary)
          }
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .background(Color.marketCard)
      .cornerRadius(CornerRadius.lg)

      Button(action: { navigateToReports = true }) {
        Image(systemName: "chart.bar.xaxis")
          .foregroundColor(.white)
          .font(Typography.title3)
      }
    }
    .padding(.horizontal, Spacing.md)
    .padding(.top, 10)
  }

  private var balanceSection: some View {
    VStack(spacing: 12) {
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

      HStack(spacing: 30) {
        ActionButton(icon: "tag.fill", label: "Add Sale") { showingAddSale = true }
        ActionButton(icon: "arrow.down.circle.fill", label: "Add Cost") { showingAddCost = true }
        ActionButton(icon: "list.bullet", label: "Details") { navigateToReports = true }
      }
    }
    .padding(.horizontal, Spacing.md)
  }

  private var recentActivitySection: some View {
    VStack(alignment: .leading) {
      Text("Recent Activity")
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal)

      ScrollView {
        VStack(spacing: 0) {
          ForEach(filteredActivities.prefix(5)) { activity in
            ActivityRow(
              activity: activity,
              currency: profileVM.currencySymbol
            )

            if activity.id != filteredActivities.prefix(5).last?.id {
              Divider()
                .background(Color.marketCard)
                .padding(.leading, 50)
            }
          }

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
  }

  private func loadData() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { await self.salesVM.fetchSales() }
      group.addTask { await self.costsVM.fetchCosts() }
      group.addTask { await self.fetchActivities() }
    }
  }

  private func fetchActivities() async {
    do {
      activities = try await ActivityService.fetchRecent(limit: 50)
    } catch {
      activities = []
    }
  }

  private func filterByDate<T>(_ items: [T], dateKey: KeyPath<T, Date>) -> [T] {
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
}

struct ActionButton: View {
  let icon: String
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Circle()
          .fill(Color.marketCard)
          .frame(width: 50, height: 50)
          .overlay(
            Image(systemName: icon)
              .font(Typography.title3)
              .foregroundColor(.white)
          )

        Text(label)
          .font(.caption)
          .foregroundColor(.white)
      }
    }
  }
}
