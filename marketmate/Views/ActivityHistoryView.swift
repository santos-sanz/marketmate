import SwiftUI

struct ActivityHistoryView: View {
  @StateObject private var viewModel = ActivityViewModel()
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var profileVM: ProfileViewModel  // To get currency
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var salesVM: SalesViewModel

  @State private var showingFilters = false
  @State private var expandedActivityId: UUID? = nil
  @State private var sheetType: SheetType?

  enum SheetType: Identifiable {
    case editProduct(Product)
    case editCost(Cost)
    case editMarket(Market)
    case editSale(Sale)

    var id: String {
      switch self {
      case .editProduct(let p): return "product-\(p.id)"
      case .editCost(let c): return "cost-\(c.id)"
      case .editMarket(let m): return "market-\(m.id)"
      case .editSale(let s): return "sale-\(s.id)"
      }
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color.clear.revolutBackground().ignoresSafeArea()

        VStack(spacing: 0) {
          // Search and Filter Bar
          HStack(spacing: 12) {
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(.marketTextSecondary)
              TextField("Search", text: $viewModel.searchText)
                .foregroundColor(.white)
                .accentColor(.white)
            }
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)

            Button(action: { showingFilters = true }) {
              Image(systemName: "slider.horizontal.3")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 12)
          .background(Color.white.opacity(0.05))

          if viewModel.isLoading {
            Spacer()
            ProgressView()
              .tint(.white)
          } else if viewModel.activities.isEmpty {
            Spacer()
            Text("No activities found")
              .foregroundColor(.marketTextSecondary)
            Spacer()
          } else {
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.groupedActivities(), id: \.key) { group in
                  VStack(alignment: .leading, spacing: 8) {
                    Text(group.key)
                      .font(.headline)
                      .foregroundColor(.white)
                      .padding(.horizontal)

                    VStack(spacing: 0) {
                      ForEach(group.value) { activity in
                        VStack(spacing: 0) {
                          ActivityRow(
                            activity: activity,
                            currency: profileVM.currencySymbol
                          )
                          .contentShape(Rectangle())
                          .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                              if expandedActivityId == activity.id {
                                expandedActivityId = nil
                                viewModel.expandedDetails = nil
                              } else {
                                expandedActivityId = activity.id
                                Task {
                                  await viewModel.fetchDetails(for: activity)
                                }
                              }
                            }
                          }

                          if expandedActivityId == activity.id {
                            ExpandedActivityView(
                              activity: activity,
                              viewModel: viewModel,
                              onEdit: { type in
                                sheetType = type
                              }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                          }

                          if activity.id != group.value.last?.id {
                            Divider()
                              .background(Color.white.opacity(0.1))
                              .padding(.leading, 50)
                          }
                        }
                      }
                    }
                    .background(Color.marketCard)
                    .cornerRadius(16)
                    .padding(.horizontal)
                  }
                }
              }
              .padding(.top)
              .padding(.bottom, 20)
            }
          }
        }
      }
      .navigationTitle("Activity")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbarColorScheme(.dark, for: .navigationBar)
      .onAppear {
        Task {
          await viewModel.fetchActivities()
        }
      }
      .sheet(isPresented: $showingFilters) {
        FilterSheet(viewModel: viewModel)
          .presentationDetents([.medium])
          .presentationDragIndicator(.visible)
      }
      .sheet(
        item: $sheetType,
        onDismiss: {
          Task {
            await viewModel.fetchActivities()
          }
        }
      ) { type in
        switch type {
        case .editProduct(let product):
          NavigationView {
            AddProductView(productToEdit: product)
              .environmentObject(inventoryVM)
          }
        case .editCost(let cost):
          NavigationView {
            AddCostView(costToEdit: cost)
              .environmentObject(costsVM)
          }
        case .editMarket(let market):
          EditMarketView(market: market)
            .environmentObject(MarketSessionManager())  // New instance for editing
        case .editSale(let sale):
          EditSaleView(sale: sale)
            .environmentObject(salesVM)
        }
      }
    }
  }
}

struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(isSelected ? .black : .white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(isSelected ? Color.white : Color.white.opacity(0.1))
        )
    }
  }
}

#Preview {
  ActivityHistoryView()
    .environmentObject(ProfileViewModel())
}

struct ExpandedActivityView: View {
  let activity: Activity
  @ObservedObject var viewModel: ActivityViewModel
  var onEdit: (ActivityHistoryView.SheetType) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Basic Info (Always shown)
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Date")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(activity.createdAt.formatted(date: .long, time: .standard))
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      if viewModel.isLoadingDetails {
        ProgressView()
          .tint(.white)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical)
      } else if let details = viewModel.expandedDetails {
        Divider().background(Color.white.opacity(0.1))

        switch details {
        case .sale(let sale):
          SaleDetailsView(sale: sale)
        case .cost(let cost):
          CostDetailsView(cost: cost)
        case .product(let product):
          ProductDetailsView(product: product)
        case .market(let market):
          MarketDetailsView(market: market)
        }
      } else {
        // Fallback for simple activities or if fetch failed/not needed
        if let amount = activity.amount {
          Divider().background(Color.white.opacity(0.1))
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Amount")
                .font(.caption)
                .foregroundColor(.marketTextSecondary)
              Text(String(format: "%.2f", amount))
                .font(.subheadline)
                .foregroundColor(.white)
            }
            Spacer()
          }
        }
      }
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .overlay(alignment: .topTrailing) {
      if let details = viewModel.expandedDetails {
        Button(action: {
          switch details {
          case .sale(let sale):
            onEdit(.editSale(sale))
          case .cost(let cost):
            onEdit(.editCost(cost))
          case .product(let product):
            onEdit(.editProduct(product))
          case .market(let market):
            onEdit(.editMarket(market))
          }
        }) {
          Image(systemName: "pencil.circle.fill")
            .font(.title2)
            .foregroundColor(.marketBlue)
            .padding(8)
        }
      }
    }
  }
}

struct SaleDetailsView: View {
  let sale: Sale

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Market Location
      if let location = sale.marketLocation {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Market")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(location)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
        Divider().background(Color.white.opacity(0.1))
      }

      // Payment Method
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Payment Method")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(sale.paymentMethod)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      Divider().background(Color.white.opacity(0.1))

      // Items
      if let items = sale.items, !items.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Items")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)

          ForEach(items) { item in
            HStack {
              Text("\(item.quantity)x \(item.productName)")
                .font(.subheadline)
                .foregroundColor(.white)
              Spacer()
              Text(String(format: "%.2f", item.priceAtSale * Double(item.quantity)))
                .font(.subheadline)
                .foregroundColor(.white)
            }
          }
        }
        Divider().background(Color.white.opacity(0.1))
      }

      // Total
      HStack {
        Text("Total")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
        Text(String(format: "%.2f", sale.totalAmount))
          .font(.headline)
          .foregroundColor(.marketGreen)
      }
    }
  }
}

struct CostDetailsView: View {
  let cost: Cost
  @EnvironmentObject var costsVM: CostsViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let categoryId = cost.categoryId,
        let categoryName = costsVM.categories.first(where: { $0.id == categoryId })?.name
      {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Category")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(categoryName)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
        Divider().background(Color.white.opacity(0.1))
      }

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Description")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(cost.description)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      Divider().background(Color.white.opacity(0.1))

      HStack {
        Text("Amount")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
        Text(String(format: "%.2f", cost.amount))
          .font(.headline)
          .foregroundColor(.red)
      }
    }
  }
}

struct ProductDetailsView: View {
  let product: Product
  @EnvironmentObject var inventoryVM: InventoryViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Product Name")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(product.name)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      Divider().background(Color.white.opacity(0.1))

      if let description = product.description, !description.isEmpty {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Description")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(description)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
        Divider().background(Color.white.opacity(0.1))
      }

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Price")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(String(format: "%.2f", product.price))
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()

        if let cost = product.cost {
          VStack(alignment: .trailing, spacing: 4) {
            Text("Cost")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(String(format: "%.2f", cost))
              .font(.subheadline)
              .foregroundColor(.white)
          }
        }
      }

      if let stock = product.stockQuantity {
        Divider().background(Color.white.opacity(0.1))
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Stock Quantity")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text("\(stock)")
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
      }

      if let categoryId = product.categoryId,
        let categoryName = inventoryVM.categories.first(where: { $0.id == categoryId })?.name
      {
        Divider().background(Color.white.opacity(0.1))
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Category")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(categoryName)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
      }
    }
  }
}

struct MarketDetailsView: View {
  let market: Market

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Market Name")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(market.name)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()
      }

      if let location = market.location {
        Divider().background(Color.white.opacity(0.1))
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Location")
              .font(.caption)
              .foregroundColor(.marketTextSecondary)
            Text(location)
              .font(.subheadline)
              .foregroundColor(.white)
          }
          Spacer()
        }
      }

      Divider().background(Color.white.opacity(0.1))

      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Date")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(market.date.formatted(date: .long, time: .omitted))
            .font(.subheadline)
            .foregroundColor(.white)
        }
        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          Text("Status")
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
          Text(market.isOpen ? "Open" : "Closed")
            .font(.subheadline)
            .foregroundColor(market.isOpen ? .marketGreen : .red)

          if !market.isOpen, let endTime = market.endTime {
            Text(endTime.formatted(date: .omitted, time: .shortened))
              .font(.caption2)
              .foregroundColor(.marketTextSecondary)
          }
        }
      }
    }
  }
}

struct FilterSheet: View {
  @ObservedObject var viewModel: ActivityViewModel
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(alignment: .leading, spacing: 24) {
        Text("Filters")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.top)

        // Type Filter
        VStack(alignment: .leading, spacing: 12) {
          Text("Type")
            .font(.headline)
            .foregroundColor(.marketTextSecondary)

          FlowLayout(spacing: 10) {
            ForEach(ActivityViewModel.ActivityFilter.allCases) { filter in
              FilterChip(
                title: filter.rawValue,
                isSelected: viewModel.selectedFilter == filter,
                action: { viewModel.selectedFilter = filter }
              )
            }
          }
        }

        // Date Filter
        VStack(alignment: .leading, spacing: 12) {
          Text("Time")
            .font(.headline)
            .foregroundColor(.marketTextSecondary)

          FlowLayout(spacing: 10) {
            ForEach(ActivityViewModel.DateFilter.allCases) { filter in
              FilterChip(
                title: filter.rawValue,
                isSelected: viewModel.selectedDateFilter == filter,
                action: { viewModel.selectedDateFilter = filter }
              )
            }
          }
        }

        Spacer()

        Button(action: { dismiss() }) {
          Text("Apply")
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
      }
      .padding()
    }
  }
}

// Simple FlowLayout helper
struct FlowLayout: Layout {
  var spacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = flow(proposal: proposal, subviews: subviews, spacing: spacing)
    return result.size
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let result = flow(proposal: proposal, subviews: subviews, spacing: spacing)
    for (index, point) in result.points.enumerated() {
      subviews[index].place(
        at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
    }
  }

  struct FlowResult {
    var size: CGSize
    var points: [CGPoint]
  }

  func flow(proposal: ProposedViewSize, subviews: Subviews, spacing: CGFloat) -> FlowResult {
    let maxWidth = proposal.width ?? .infinity
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0
    var points: [CGPoint] = []

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if currentX + size.width > maxWidth {
        currentX = 0
        currentY += lineHeight + spacing
        lineHeight = 0
      }

      points.append(CGPoint(x: currentX, y: currentY))
      lineHeight = max(lineHeight, size.height)
      currentX += size.width + spacing
    }

    return FlowResult(size: CGSize(width: maxWidth, height: currentY + lineHeight), points: points)
  }
}
