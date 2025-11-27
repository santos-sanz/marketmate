import Supabase
import SwiftUI

struct InventoryView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @State private var showingAddProduct = false
  @State private var searchText = ""
  @State private var selectedProduct: Product?
  @State private var activities: [Activity] = []
  private let client = SupabaseService.shared.client

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
          Button(action: {}) {
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
          List {
            Section {
              // Recent Activity Section (Products Only)
              VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                  .font(.headline)
                  .foregroundColor(.white)

                ForEach(
                  activities.filter {
                    [.productCreated, .productUpdated, .productDeleted].contains($0.type)
                  }.prefix(5)
                ) { activity in
                  ActivityRow(
                    activity: activity,
                    currency: profileVM.currencySymbol
                  )
                }
              }
              .listRowBackground(Color.clear)
            }

            ForEach(filteredProducts) { product in
              NavigationLink(
                destination: ProductDetailView(product: product).environmentObject(inventoryVM)
              ) {
                ProductRowView(product: product)
              }
              .listRowBackground(Color.marketCard)
              .listRowSeparator(.hidden)
              .padding(.vertical, 4)
            }
            .onDelete { indexSet in
              Task {
                for index in indexSet {
                  await inventoryVM.deleteProduct(id: filteredProducts[index].id)
                }
              }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .background(Color.clear)
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
    guard let userId = client.auth.currentUser?.id else { return }

    do {
      let fetchedActivities: [Activity] =
        try await client
        .from("recent_activity")
        .select()
        .eq("user_id", value: userId)
        .order("created_at", ascending: false)
        .limit(20)
        .execute()
        .value

      self.activities = fetchedActivities
    } catch {
      print("❌ [InventoryView] Error fetching activities: \(error)")
    }
  }
}

struct ProductRowView: View {
  let product: Product
  @EnvironmentObject var profileVM: ProfileViewModel

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(product.name)
          .font(.headline)
          .foregroundColor(.white)

        if let description = product.description {
          Text(description)
            .font(.caption)
            .foregroundColor(.marketTextSecondary)
            .lineLimit(1)
        }
      }
      Spacer()

      VStack(alignment: .trailing) {
        Text("\(profileVM.currencySymbol) \(String(format: "%.2f", product.price))")
          .font(.headline)
          .foregroundColor(.white)

        if let stock = product.stockQuantity {
          Text("\(stock) in stock")
            .font(.caption)
            .foregroundColor(stock > 0 ? .marketTextSecondary : .red)
        }
      }
    }
    .padding()
    .marketCardStyle()
  }
}
