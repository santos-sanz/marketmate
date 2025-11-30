import SwiftUI

struct InventoryView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @State private var showingAddProduct = false
  @State private var searchText = ""
  @State private var selectedProduct: Product?
  @State private var activities: [Activity] = []

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
              .foregroundColor(.white.opacity(0.8))
          }

          // Search Bar
          HStack {
            Image(systemName: "magnifyingglass")
              .foregroundColor(.white.opacity(0.8))
            TextField("", text: $searchText)
              .foregroundColor(.white)
              .accentColor(.white)
              .placeholder(when: searchText.isEmpty) {
                Text("Search").foregroundColor(.white)
              }
          }
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(Color.white.opacity(0.3))
          .cornerRadius(20)

          Button(action: {}) {
            Image(systemName: "chart.bar.xaxis")
              .foregroundColor(.white)
              .font(Typography.title3)
          }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, 10)
        .padding(.bottom, Spacing.xs)

        // Content
        if inventoryVM.isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .marketBlue))
        } else if inventoryVM.products.isEmpty {
          VStack(spacing: 20) {
            Image(systemName: "cube.box")
              .font(.system(size: 60))
              .foregroundColor(.marketTextSecondary)
            Text("No products yet")
              .font(.title2)
              .foregroundColor(.marketTextSecondary)
            Button(action: { showingAddProduct = true }) {
              Text("Add your first product")
                .primaryButtonStyle()
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
                    .foregroundColor(.white)
                  Spacer()
                  NavigationLink(
                    destination: ActivityHistoryView(initialFilter: .products).environmentObject(
                      profileVM)
                  ) {
                    Text("Show all")
                      .font(.subheadline)
                      .foregroundColor(.marketBlue)
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
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.marketBlue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
            }
            .padding()
          }
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

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(product.name)
        .font(Typography.subheadline)
        .foregroundColor(.white)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()

      if let stock = product.stockQuantity {
        Text("\(stock) in stock")
          .font(Typography.caption1)
          .fontWeight(.semibold)
          .foregroundColor(stock > 0 ? .white : .red)
      }
    }
    .padding(Spacing.sm)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.marketCard)
    .cornerRadius(CornerRadius.sm)
  }
}
