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
              .foregroundColor(.white.opacity(0.8))
            TextField("Search", text: $searchText)
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
        }

        // Products Grid & Recent Sales
        ScrollView {
          VStack(spacing: Spacing.md) {
            // Products Grid
            LazyVGrid(
              columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
              spacing: Spacing.xs
            ) {  // 3 columns for compactness
              // Custom Amount Button
              Button(action: {
                // TODO: Handle custom amount logic
              }) {
                VStack(spacing: 4) {
                  Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundColor(.white)
                  Text("Custom")
                    .font(Typography.caption1)
                    .foregroundColor(.white)
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(Color.marketBlue.opacity(0.6))
                .cornerRadius(CornerRadius.sm)
              }

              ForEach(filteredProducts) { product in
                ProductCard(
                  product: product,
                  action: {
                    salesVM.addToCart(product: product)
                  }, isSelected: false
                )
              }
            }
            .padding(.horizontal, Spacing.sm)

            // Recent Sales Section
            VStack(alignment: .leading, spacing: Spacing.sm) {
              Text("Recent Sales")
                .font(Typography.headline)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.sm)

              ForEach(salesVM.sales.prefix(5)) { sale in
                HStack {
                  VStack(alignment: .leading) {
                    Text("Sale")
                      .font(Typography.subheadline)
                      .foregroundColor(.white)
                    if let location = sale.marketLocation {
                      Text(location)
                        .font(Typography.caption1)
                        .foregroundColor(.white.opacity(0.7))
                    }
                  }
                  Spacer()
                  Text("\(profileVM.currencySymbol) \(String(format: "%.2f", sale.totalAmount))")
                    .font(Typography.subheadline)
                    .bold()
                    .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
              }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.bottom, 100)  // Space for cart summary
          }
        }

        // Cart Summary
        if !salesVM.cartItems.isEmpty {
          VStack(spacing: Spacing.sm) {
            HStack {
              Text("Total:")
                .font(Typography.title3)
                .foregroundColor(.white)
              Spacer()
              Text("\(profileVM.currencySymbol) \(String(format: "%.2f", salesVM.cartTotal))")
                .font(Typography.display)
                .fontWeight(.bold)
                .foregroundColor(.white)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            Button(action: {
              print("🛒 [SalesView] Checkout button pressed. Cart total: \(salesVM.cartTotal)")
              showingCheckout = true
            }) {
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

      if showingStartMarket {
        StartMarketModal(
          isPresented: $showingStartMarket,
          marketName: $marketLocation,
          locationManager: locationManager,
          onStart: {
            Task {
              await marketSession.startMarket(
                location: marketLocation.isEmpty ? "Market" : marketLocation,
                latitude: locationManager.location?.coordinate.latitude,
                longitude: locationManager.location?.coordinate.longitude
              )
              locationManager.stopUpdatingLocation()
              showingStartMarket = false
            }
          }
        )
      }
    }
    .navigationBarHidden(true)
    .navigationDestination(isPresented: $showingCheckout) {
      CheckoutView()
        .environmentObject(salesVM)
        .environmentObject(marketSession)
        .onAppear {
          print("🛒 [CheckoutView] View appeared successfully")
        }
    }
    .onAppear {
      Task {
        await marketSession.checkForActiveMarket()
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

        Text("\(profileVM.currencySymbol) \(String(format: "%.2f", product.price))")
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
