import CoreLocation
import SwiftUI

struct SalesView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @StateObject private var marketSession = MarketSessionManager()
  @StateObject private var locationManager = LocationManager()
  @EnvironmentObject var profileVM: ProfileViewModel
  @State private var showingCheckout = false
  @State private var showingStartMarket = false
  @State private var marketLocation = ""
  @State private var searchText = ""

  var filteredProducts: [Product] {
    if searchText.isEmpty {
      return inventoryVM.products
    } else {
      return inventoryVM.products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
  }

  let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]

  var body: some View {
    NavigationView {
      ZStack {
        // Gradient Background
        Color.clear.revolutBackground()

        VStack(spacing: 0) {
          // Header (Profile, Search, Market)
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
                .foregroundColor(.white.opacity(0.6))
              TextField("Search", text: $searchText)
                .foregroundColor(.white)
                .accentColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)

            Button(action: {
              locationManager.requestPermission()
              locationManager.startUpdatingLocation()
              showingStartMarket = true
            }) {
              Image(systemName: "tent.fill")
                .foregroundColor(.white)
                .font(.system(size: 24))
            }
          }
          .padding(.horizontal)
          .padding(.top, 10)
          .padding(.bottom, 8)

          // Market Status Banner
          if let market = marketSession.activeMarket {
            HStack {
              Image(systemName: "tent.fill")
                .foregroundColor(.white)
              Text("Open Market: \(market.location ?? "Unknown")")
                .font(.headline)
                .foregroundColor(.white)
              Spacer()
              Button(action: { Task { await marketSession.endMarket() } }) {
                Text("End")
                  .font(.caption)
                  .bold()
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .background(Color.white.opacity(0.2))
                  .foregroundColor(.white)
                  .cornerRadius(12)
              }
            }
            .padding()
            .background(Color.marketBlue.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal)
            .animation(.easeInOut, value: marketSession.activeMarket)
          }

          // Products Grid - 2 Columns for more density
          ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm)
            {
              ForEach(filteredProducts) { product in
                ProductCard(
                  product: product,
                  action: {
                    salesVM.addToCart(product: product)
                  }, isSelected: false
                )
              }
            }
            .padding(Spacing.sm)
            .animation(.spring(), value: filteredProducts)
          }

          // Cart Summary
          if !salesVM.cartItems.isEmpty {
            VStack(spacing: Spacing.sm) {
              HStack {
                Text("Total:")
                  .font(Typography.title3)
                  .foregroundColor(.white)
                Spacer()
                Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", salesVM.cartTotal))")
                  .font(Typography.display)
                  .fontWeight(.bold)
                  .foregroundColor(.white)
              }
              .padding(.horizontal, Spacing.md)
              .padding(.top, Spacing.sm)

              Button(action: { showingCheckout = true }) {
                Text("Checkout")
                  .font(Typography.headline)
                  .fontWeight(.semibold)
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding(Spacing.md)
                  .background(Color.marketBlue)
                  .cornerRadius(CornerRadius.xl)
              }
              .padding(.horizontal, Spacing.md)
              .padding(.bottom, Spacing.md)
            }
            .background(
              Color.marketBlue.opacity(0.5)
                .background(.ultraThinMaterial)
            )
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(
              color: Shadow.floating.color, radius: Shadow.floating.radius, x: Shadow.floating.x,
              y: Shadow.floating.y)
          }
        }
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showingCheckout) {
        CheckoutView()
          .environmentObject(salesVM)
          .environmentObject(marketSession)
      }
      .alert("Open Market", isPresented: $showingStartMarket) {
        TextField("Location", text: $marketLocation)
        Button(
          "Start",
          action: {
            Task {
              await marketSession.startMarket(
                location: marketLocation.isEmpty ? "Location" : marketLocation,
                latitude: locationManager.location?.coordinate.latitude,
                longitude: locationManager.location?.coordinate.longitude
              )
              locationManager.stopUpdatingLocation()
            }
          })
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Enter the location of the market.")
      }
    }
    .onAppear {
      Task {
        await inventoryVM.fetchProducts()
      }
    }
  }
}

struct ProductCard: View {
  let product: Product
  let action: () -> Void
  let isSelected: Bool
  @EnvironmentObject var profileVM: ProfileViewModel

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: Spacing.xxs) {
        Text(product.name)
          .font(Typography.headline)
          .foregroundColor(.white)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()

        Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", product.price))")
          .font(Typography.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)
      }
      .frame(height: 100)
      .padding(Spacing.sm)
      .background(Color.white.opacity(0.15))
      .cornerRadius(CornerRadius.sm)
    }
  }
}

extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect, byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius))
    return Path(path.cgPath)
  }
}
