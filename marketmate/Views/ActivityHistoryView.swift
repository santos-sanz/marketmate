import SwiftUI

struct ActivityHistoryView: View {
  @StateObject private var viewModel = ActivityViewModel()
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var profileVM: ProfileViewModel  // To get currency
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var themeManager: ThemeManager

  @State private var showingFilters = false
  @State private var expandedActivityId: UUID? = nil
  @State private var sheetType: SheetType?
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var fieldBackground: Color { themeManager.fieldBackground }
  private var strokeColor: Color { themeManager.strokeColor }

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

  var initialFilter: ActivityViewModel.ActivityFilter?

  var body: some View {
    NavigationStack {
      ZStack {
        Color.clear.revolutBackground().ignoresSafeArea()

        VStack(spacing: 0) {
          // Search and Filter Bar
          HStack(spacing: 12) {
            HStack {
              Image(systemName: "magnifyingglass")
                .foregroundColor(secondaryTextColor)
              TextField("Search", text: $viewModel.searchText)
                .foregroundColor(textColor)
                .accentColor(textColor)
            }
            .padding(10)
            .background(fieldBackground)
            .overlay(
              RoundedRectangle(cornerRadius: 10)
                .stroke(strokeColor, lineWidth: 1)
            )
            .cornerRadius(10)

            Button(action: { showingFilters = true }) {
              Image(systemName: "slider.horizontal.3")
                .font(.system(size: 20))
                .foregroundColor(textColor)
                .frame(width: 44, height: 44)
                .background(themeManager.translucentOverlay)
                .cornerRadius(10)
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 12)
          .background(themeManager.translucentOverlay)

          if viewModel.isLoading {
            Spacer()
            ProgressView()
              .tint(textColor)
          } else if viewModel.activities.isEmpty {
            Spacer()
            Text("No activities found")
              .foregroundColor(secondaryTextColor)
            Spacer()
          } else {
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.groupedActivities(), id: \.key) { group in
                  VStack(alignment: .leading, spacing: 8) {
                    Text(group.key)
                      .font(.headline)
                      .foregroundColor(textColor)
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

                          if expandedActivityId == activity.id {
                            ExpandedActivityView(
                              activity: activity,
                              viewModel: viewModel,
                              onEdit: { type in
                                sheetType = type
                              }
                            )
                          }

                          if activity.id != group.value.last?.id {
                            Divider()
                              .background(strokeColor)
                              .padding(.leading, 50)
                          }
                        }
                      }
                    }
                    .background(cardBackground)
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
        if let filter = initialFilter {
          if filter == .products && !profileVM.useInventory {
            viewModel.selectedFilter = .all
          } else {
            viewModel.selectedFilter = filter
          }
        }
        viewModel.includeInventoryActivities = profileVM.useInventory
        Task {
          await viewModel.fetchActivities()
        }
      }
      .onChange(of: profileVM.useInventory) { newValue in
        viewModel.includeInventoryActivities = newValue
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
    .themedNavigationBars(themeManager)
  }
}

struct FilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  @EnvironmentObject var themeManager: ThemeManager

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(isSelected ? textColor : secondaryTextColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(
              isSelected ? themeManager.primaryTextColor.opacity(0.14)
                : themeManager.translucentOverlay)
        )
    }
  }
}

#Preview {
  ActivityHistoryView()
    .environmentObject(ProfileViewModel())
    .environmentObject(InventoryViewModel())
    .environmentObject(CostsViewModel())
    .environmentObject(SalesViewModel())
    .environmentObject(ThemeManager())
}

struct FilterSheet: View {
  @ObservedObject var viewModel: ActivityViewModel
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var themeManager: ThemeManager
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

  var body: some View {
    ZStack {
      themeManager.backgroundColor.ignoresSafeArea()

      VStack(alignment: .leading, spacing: 24) {
        Text("Filters")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(textColor)
          .padding(.top)

        // Type Filter
        VStack(alignment: .leading, spacing: 12) {
          Text("Type")
            .font(.headline)
            .foregroundColor(secondaryTextColor)

          FlowLayout(spacing: 10) {
            ForEach(viewModel.availableFilters) { filter in
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
            .foregroundColor(secondaryTextColor)

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
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(cardBackground)
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
