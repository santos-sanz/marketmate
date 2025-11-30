import CoreLocation
import SwiftUI

struct SalesView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @StateObject private var marketSession = MarketSessionManager()
  @StateObject private var locationManager = LocationManager()
  @EnvironmentObject var profileVM: ProfileViewModel

  @State private var showingCheckout = false
  @State private var showingStartMarket = false
  @State private var showingCustomAmount = false
  @State private var customAmount = ""
  @State private var customDescription = ""
  @State private var marketLocation = ""
  @State private var searchText = ""
  @State private var activities: [Activity] = []

  private var filteredProducts: [Product] {
    if searchText.isEmpty {
      return inventoryVM.products
    } else {
      return inventoryVM.products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
  }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      VStack(spacing: 0) {
        header
        if let market = marketSession.activeMarket {
          marketBanner(for: market)
        }
        ScrollView {
          VStack(spacing: Spacing.md) {
            productGrid
            salesActivity
          }
        }

        if !salesVM.cartItems.isEmpty {
          cartSummary
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
    .sheet(isPresented: $showingCustomAmount) { customAmountSheet }
    .navigationBarHidden(true)
    .navigationDestination(isPresented: $showingCheckout) {
      CheckoutView()
        .environmentObject(salesVM)
        .environmentObject(marketSession)
    }
    .onAppear {
      Task {
        await marketSession.checkForActiveMarket()
        await inventoryVM.fetchProducts()
        await fetchActivities()
      }
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      NavigationLink(destination: ProfileView().environmentObject(profileVM)) {
        Image(systemName: "person.crop.circle.fill")
          .resizable()
          .frame(width: 40, height: 40)
          .foregroundColor(.marketTextSecondary)
      }

      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.marketTextSecondary)
        TextField("Search", text: $searchText)
          .foregroundColor(.white)
          .accentColor(.white)
          .placeholder(when: searchText.isEmpty) {
            Text("Search").foregroundColor(.white)
          }
      }
      .searchBarStyle()

      Button(action: {
        locationManager.requestPermission()
        locationManager.startUpdatingLocation()
        showingStartMarket = true
      }) {
        Image(systemName: "tent.fill")
          .foregroundColor(.white)
          .font(Typography.title2)
      }
    }
    .padding(.horizontal)
    .padding(.top, 10)
    .padding(.bottom, 8)
  }

  private func marketBanner(for market: Market) -> some View {
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

  private var productGrid: some View {
    VStack(spacing: Spacing.md) {
      LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
        spacing: Spacing.xs
      ) {
        Color.clear
          .aspectRatio(1.5, contentMode: .fit)
          .overlay(
            Button(action: { showingCustomAmount = true }) {
              VStack(spacing: 4) {
                Image(systemName: "keyboard")
                  .font(.title2)
                  .foregroundColor(.white)
                Text("Custom")
                  .font(Typography.caption1)
                  .foregroundColor(.white)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(Color.marketBlue.opacity(0.6))
              .cornerRadius(CornerRadius.sm)
            }
          )

        ForEach(filteredProducts.prefix(8)) { product in
          Color.clear
            .aspectRatio(1.5, contentMode: .fit)
            .overlay(
              ProductCard(
                product: product,
                action: { salesVM.addToCart(product: product) }
              )
              .environmentObject(profileVM)
            )
        }
      }

      if filteredProducts.count > 8 {
        NavigationLink(
          destination: AllProductsView()
            .environmentObject(inventoryVM)
            .environmentObject(salesVM)
            .environmentObject(profileVM)
        ) {
          HStack {
            Text("Show all products")
              .font(Typography.subheadline)
              .fontWeight(.medium)
            Image(systemName: "arrow.right")
              .font(.caption)
          }
          .foregroundColor(.white)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity)
          .background(Color.white.opacity(0.1))
          .cornerRadius(CornerRadius.sm)
        }
      }
    }
    .padding(.horizontal, Spacing.sm)
  }

  private var salesActivity: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      HStack {
        Text("Recent Activity")
          .font(Typography.headline)
          .foregroundColor(.white)
        Spacer()
        NavigationLink(
          destination: ActivityHistoryView(initialFilter: .sales).environmentObject(profileVM)
        ) {
          Text("Show all")
            .font(.subheadline)
            .foregroundColor(.marketBlue)
        }
      }
      .padding(.horizontal, Spacing.sm)

      ForEach(activities.filter { $0.type == .sale }.prefix(3)) { activity in
        ActivityRow(
          activity: activity,
          currency: profileVM.currencySymbol
        )
      }
    }
    .padding(.horizontal, Spacing.sm)
    .padding(.bottom, 100)
  }

  private var cartSummary: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 2) {
          Text("\(salesVM.cartItems.reduce(0) { $0 + $1.quantity }) items")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.8))

          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("Total")
              .font(.subheadline)
              .foregroundColor(.white.opacity(0.8))

            Text("\(profileVM.currencySymbol) \(String(format: "%.2f", salesVM.cartTotal))")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.white)
          }
        }

        Spacer()

        Button(action: { showingCheckout = true }) {
          HStack {
            Text("Checkout")
              .font(.headline)
              .fontWeight(.semibold)
            Image(systemName: "arrow.right")
              .font(.headline)
          }
          .foregroundColor(.marketBlue)
          .padding(.vertical, 12)
          .padding(.horizontal, 20)
          .background(Color.white)
          .cornerRadius(30)
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
      .padding(.bottom, 8)
    }
    .background(
      Rectangle()
        .fill(.ultraThinMaterial)
        .overlay(Color.black.opacity(0.2))
    )
    .cornerRadius(24, corners: [.topLeft, .topRight])
    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
  }

  private var customAmountSheet: some View {
    ZStack {
      Color.marketBlue.edgesIgnoringSafeArea(.all)

      VStack(spacing: 24) {
        Text("Add Custom Amount")
          .font(Typography.title3)
          .foregroundColor(.white)
          .bold()

        VStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
              .font(Typography.caption1)
              .foregroundColor(.marketTextSecondary)

            HStack {
              Text(profileVM.currencySymbol)
                .foregroundColor(.white)
                .font(.title2)
              TextField("\(profileVM.currencySymbol) 0.00", text: $customAmount)
                .currencyInput(text: $customAmount)
                .foregroundColor(.white)
                .font(.title2)
            }
            .padding()
            .background(Color.marketCard)
            .cornerRadius(12)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Description")
              .font(Typography.caption1)
              .foregroundColor(.marketTextSecondary)

            TextField("Item Name", text: $customDescription)
              .foregroundColor(.white)
              .padding()
              .background(Color.marketCard)
              .cornerRadius(12)
          }
        }

        HStack(spacing: 16) {
          Button(action: {
            showingCustomAmount = false
            customAmount = ""
            customDescription = ""
          }) {
            Text("Cancel")
              .font(Typography.body)
              .foregroundColor(.marketTextSecondary)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.marketCard)
              .cornerRadius(12)
          }

          Button(action: addCustomAmount) {
            Text("Add")
              .font(Typography.body)
              .bold()
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.white.opacity(0.2))
              .cornerRadius(12)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.white.opacity(0.5), lineWidth: 1)
              )
          }
          .disabled(customAmount.isEmpty)
          .opacity(customAmount.isEmpty ? 0.5 : 1.0)
        }
      }
      .padding(24)
    }
    .presentationDetents([.medium])
  }

  private func addCustomAmount() {
    if let amount = Double(customAmount) {
      salesVM.addCustomAmount(
        name: customDescription.isEmpty ? "Custom Amount" : customDescription,
        price: amount
      )
      showingCustomAmount = false
      customAmount = ""
      customDescription = ""
    }
  }

  private func fetchActivities() async {
    do {
      activities = try await ActivityService.fetchRecent(limit: 20)
    } catch {
      activities = []
    }
  }
}

struct ProductCard: View {
  let product: Product
  let action: () -> Void
  @EnvironmentObject var profileVM: ProfileViewModel

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 0) {
        Text(product.name)
          .font(Typography.subheadline)
          .foregroundColor(.white)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()

        Text("\(profileVM.currencySymbol) \(String(format: "%.2f", product.price))")
          .font(Typography.headline)
          .fontWeight(.bold)
          .foregroundColor(.white)
      }

      .padding(Spacing.sm)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.marketCard)
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
