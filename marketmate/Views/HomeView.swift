import SwiftUI

struct HomeView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var themeManager: ThemeManager

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

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var fieldBackground: Color { themeManager.fieldBackground }
  private var strokeColor: Color { themeManager.strokeColor }

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
          .foregroundColor(secondaryTextColor)
      }

      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(secondaryTextColor)
        TextField("", text: $searchText)
          .foregroundColor(textColor)
          .accentColor(textColor)
          .placeholder(when: searchText.isEmpty) {
            Text("Search").foregroundColor(secondaryTextColor)
          }
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .background(fieldBackground)
      .overlay(
        RoundedRectangle(cornerRadius: CornerRadius.lg)
          .stroke(strokeColor, lineWidth: 1)
      )
      .cornerRadius(CornerRadius.lg)

      Button(action: { navigateToReports = true }) {
        Image(systemName: "chart.bar.xaxis")
          .foregroundColor(textColor)
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
            .foregroundColor(secondaryTextColor)
          Image(systemName: "chevron.down")
            .font(.caption)
            .foregroundColor(secondaryTextColor)
        }
      }

      Text("\(profileVM.currencySymbol) \(String(format: "%.2f", totalBalance))")
        .font(Typography.display)
        .foregroundColor(textColor)

      HStack(spacing: 30) {
        ActionButton(icon: "tag.fill", label: "Add Sale") { showingAddSale = true }
        ActionButton(icon: "arrow.down.circle.fill", label: "Add Cost") { showingAddCost = true }

      }
    }
    .padding(.horizontal, Spacing.md)
  }

  private var recentActivitySection: some View {
    VStack(alignment: .leading) {
      Text("Recent Activity")
        .font(.headline)
        .foregroundColor(textColor)
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
                .background(strokeColor)
                .padding(.leading, 50)
            }
          }

          NavigationLink(destination: ActivityHistoryView()) {
            Text("See all")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(textColor)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
          }
        }
        .background(cardBackground)
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
      let fetched = try await ActivityService.fetchRecent(limit: 50)
      activities = profileVM.useInventory ? fetched : fetched.filter { !$0.isProductActivity }
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
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Circle()
          .fill(themeManager.cardBackground)
          .frame(width: 50, height: 50)
          .overlay(
            Image(systemName: icon)
              .font(Typography.title3)
              .foregroundColor(themeManager.primaryTextColor)
          )

        Text(label)
          .font(.caption)
          .foregroundColor(themeManager.primaryTextColor)
      }
    }
  }
}
