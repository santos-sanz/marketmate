import SwiftUI

struct HomeView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel

  // For navigation
  @State private var showingAddSale = false
  @State private var showingAddCost = false

  // Navigation States
  @State private var navigateToProfile = false
  @State private var navigateToReports = false

  var totalBalance: Double {
    // Simple calculation: Total Sales - Total Costs (from loaded data)
    // Note: This depends on what's currently loaded in VMs.
    // Ideally, we'd have a dedicated DashboardViewModel or fetch summary stats.
    let salesTotal = salesVM.sales.reduce(0) { $0 + $1.totalAmount }
    let costsTotal = costsVM.costs.reduce(0) { $0 + $1.amount }
    return salesTotal - costsTotal
  }

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
                .foregroundColor(.white.opacity(0.6))
              TextField("Search", text: $searchText)
                .foregroundColor(.white)
                .accentColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.2))
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
              Text("Total Balance")
                .font(Typography.subheadline)
                .foregroundColor(.marketTextSecondary)

              Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", totalBalance))")
                .font(Typography.display)
                .foregroundColor(.white)
            }

            // Action Buttons
            HStack(spacing: 30) {
              ActionButton(icon: "plus", label: "Add Sale") {
                showingAddSale = true
              }

              ActionButton(icon: "arrow.right.arrow.left", label: "Add Cost") {
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
                let allTransactions =
                  (salesVM.sales.map { TransactionWrapper(sale: $0) }
                  + costsVM.costs.map { TransactionWrapper(cost: $0) }).sorted { $0.date > $1.date }

                let filteredTransactions =
                  searchText.isEmpty
                  ? allTransactions
                  : allTransactions.filter {
                    $0.title.localizedCaseInsensitiveContains(searchText)
                      || $0.subtitle.localizedCaseInsensitiveContains(searchText)
                  }

                ForEach(filteredTransactions.prefix(20)) { transaction in
                  TransactionRow(
                    title: transaction.title,
                    subtitle: transaction.subtitle,
                    amount: transaction.amount,
                    isPositive: transaction.isPositive,
                    currency: profileVM.selectedCurrency,
                    date: transaction.date
                  )
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
      .navigationBarHidden(true)
      .sheet(isPresented: $showingAddSale) {
        SalesView()  // Or a dedicated NewSaleView if we separate it
      }
      .sheet(isPresented: $showingAddCost) {
        AddCostView()
      }
    }
    .onAppear {
      Task {
        await salesVM.fetchSales()
        await costsVM.fetchCosts()
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

struct TransactionRow: View {
  let title: String
  let subtitle: String
  let amount: Double
  let isPositive: Bool
  let currency: String
  let date: Date

  var body: some View {
    HStack {
      Circle()
        .fill(isPositive ? Color.marketGreen.opacity(0.2) : Color.red.opacity(0.2))
        .frame(width: 40, height: 40)
        .overlay(
          Image(systemName: "dollarsign.circle.fill")
            .foregroundColor(isPositive ? .marketGreen : .red)
            .font(.title2)
        )

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .foregroundColor(.white)
        Text(date.formatted(date: .omitted, time: .shortened))
          .font(.caption)
          .foregroundColor(.marketTextSecondary)
      }

      Spacer()

      Text("\(isPositive ? "+" : "-")\(currency)\(String(format: "%.2f", amount))")
        .font(.subheadline)
        .foregroundColor(isPositive ? .white : .white)
    }
    .padding()
    // Background provided by container for grouped look
  }
}

struct TransactionWrapper: Identifiable {
  let id = UUID()
  let title: String
  let subtitle: String
  let amount: Double
  let isPositive: Bool
  let date: Date

  init(sale: Sale) {
    self.title = "Sale"
    self.subtitle = sale.paymentMethod
    self.amount = sale.totalAmount
    self.isPositive = true
    self.date = sale.createdAt
  }

  init(cost: Cost) {
    self.title = cost.description
    self.subtitle = cost.category ?? "Expense"
    self.amount = cost.amount
    self.isPositive = false
    self.date = cost.createdAt
  }
}
