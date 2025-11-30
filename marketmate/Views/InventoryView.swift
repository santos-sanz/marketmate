import SwiftUI

struct InventoryView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @State private var showingAddProduct = false
  @State private var searchText = ""
  @State private var selectedProduct: Product?
  @State private var activities: [Activity] = []
  @EnvironmentObject var themeManager: ThemeManager

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var fieldBackground: Color { themeManager.fieldBackground }
  private var strokeColor: Color { themeManager.strokeColor }

  var filteredProducts: [Product] {
    if searchText.isEmpty {
      return inventoryVM.products
    } else {
      return inventoryVM.products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
  }

  var body: some View {
    ZStack {
      // Gradient Background
      Color.clear.revolutBackground()

      VStack(spacing: 0) {
        // Header (Profile, Search, Reports)
        HStack(spacing: 12) {
          NavigationLink(destination: ProfileView().environmentObject(profileVM)) {
            Image(systemName: "person.crop.circle.fill")
              .resizable()
              .frame(width: 40, height: 40)
              .foregroundColor(secondaryTextColor)
          }

          // Search Bar
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
            RoundedRectangle(cornerRadius: 20)
              .stroke(strokeColor, lineWidth: 1)
          )
          .cornerRadius(20)

          Button(action: {}) {
            Image(systemName: "chart.bar.xaxis")
              .foregroundColor(textColor)
              .font(Typography.title3)
          }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, 10)
        .padding(.bottom, Spacing.xs)

        // Content
        if inventoryVM.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: textColor))
        } else if inventoryVM.products.isEmpty {
          VStack(spacing: 20) {
            Image(systemName: "cube.box")
              .font(.system(size: 60))
              .foregroundColor(secondaryTextColor)
            Text("No products yet")
              .font(.title2)
              .foregroundColor(secondaryTextColor)
            Button(action: { showingAddProduct = true }) {
              Text("Add your first product")
                .primaryButtonStyle(themeManager: themeManager)
                .frame(width: 200)
            }
          }
        } else {
          ScrollView {
            VStack(spacing: Spacing.md) {
              // Products Grid (3 columns for inventory)
              LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: Spacing.xs
              ) {
                ForEach(filteredProducts) { product in
                  Color.clear
                    .aspectRatio(1.5, contentMode: .fit)
                    .overlay(
                      NavigationLink(value: product) {
                        InventoryProductCard(product: product)
                      }
                    )
                }
              }
              .padding(.horizontal, Spacing.sm)

              // Recent Activity Section (Products Only)
              VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                  Text("Recent Activity")
                    .font(Typography.headline)
                    .foregroundColor(textColor)
                  Spacer()
                  NavigationLink(
                    destination: ActivityHistoryView(initialFilter: .products).environmentObject(
                      profileVM)
                  ) {
                    Text("Show all")
                      .font(.subheadline)
                      .foregroundColor(textColor)
                  }
                }
                .padding(.horizontal, Spacing.sm)

                ForEach(
                  activities.filter {
                    [.productCreated, .productUpdated, .productDeleted].contains($0.type)
                  }.prefix(3)
                ) { activity in
                  ActivityRow(
                    activity: activity,
                    currency: profileVM.currencySymbol
                  )
                }
              }
              .padding(.horizontal, Spacing.sm)
              .padding(.bottom, 100)  // Space for FAB
            }
          }
        }

        // Floating Action Button
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button(action: { showingAddProduct = true }) {
              Image(systemName: "plus")
                .font(.title)
                .foregroundColor(textColor)
                .frame(width: 60, height: 60)
                .background(cardBackground)
                .clipShape(Circle())
                .shadow(color: strokeColor, radius: 4, x: 0, y: 4)
            }
            .padding()
          }
          .padding(.bottom, 80)
        }
      }
    }
    .navigationBarHidden(true)
    .navigationDestination(for: Product.self) { product in
      ProductDetailView(product: product)
        .environmentObject(inventoryVM)
    }
    .navigationDestination(isPresented: $showingAddProduct) {
      AddProductView()
        .environmentObject(inventoryVM)
    }
    .onAppear {
      Task {
        await inventoryVM.fetchProducts()
        await fetchActivities()
      }
    }
  }

  func fetchActivities() async {
    do {
      activities = try await ActivityService.fetchRecent(limit: 20)
    } catch {
      activities = []
    }
  }
}

struct InventoryProductCard: View {
  let product: Product
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(product.name)
        .font(Typography.subheadline)
        .foregroundColor(themeManager.primaryTextColor)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()

      if let stock = product.stockQuantity {
        Text("\(stock) in stock")
          .font(Typography.caption1)
          .fontWeight(.semibold)
          .foregroundColor(stock > 0 ? themeManager.primaryTextColor : .red)
      }
    }
    .padding(Spacing.sm)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(themeManager.cardBackground)
    .cornerRadius(CornerRadius.sm)
  }
}
