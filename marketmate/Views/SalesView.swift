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
  @State private var customQuantity = 1
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

  private var quickAmounts: [Double] {
    [5, 10, 20, 50]
  }

  private var customAmountValue: Double? {
    Double(customAmount)
  }

  private var canAddCustomAmount: Bool {
    guard let value = customAmountValue else { return false }
    return value > 0
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
            if profileVM.useInventory {
              productGrid
            } else {
              customSalesComposer

              if !salesVM.cartItems.isEmpty {
                customCartList
              }
            }
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
        if profileVM.useInventory {
          await inventoryVM.fetchProducts()
        }
        await fetchActivities()
        if !profileVM.useInventory {
          salesVM.removeInventoryItemsFromCart()
        }
      }
    }
    .onChange(of: profileVM.useInventory) { newValue in
      if newValue {
        Task {
          await inventoryVM.fetchProducts()
        }
      } else {
        searchText = ""
        showingCustomAmount = false
        salesVM.removeInventoryItemsFromCart()
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

      if profileVM.useInventory {
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
      } else {
        VStack(alignment: .leading, spacing: 2) {
          Text("Custom Sales")
            .font(Typography.subheadline)
            .foregroundColor(.white)
          Text("Inventory features hidden")
            .font(Typography.caption1)
            .foregroundColor(.marketTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }

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

  private var customSalesComposer: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Charge custom amount")
            .font(Typography.headline)
            .foregroundColor(.white)
          Text("Build a sale without inventory items.")
            .font(Typography.caption1)
            .foregroundColor(.marketTextSecondary)
        }
        Spacer()
        Text("Inventory off")
          .font(Typography.caption1)
          .foregroundColor(.marketBlue)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.marketBlue.opacity(0.15))
          .cornerRadius(20)
      }

      VStack(alignment: .leading, spacing: 12) {
        Text("Amount")
          .font(Typography.caption1)
          .foregroundColor(.marketTextSecondary)

        HStack(spacing: 12) {
          Text(profileVM.currencySymbol)
            .foregroundColor(.marketTextSecondary)
            .font(.title2)
          TextField("0.00", text: $customAmount)
            .currencyInput(text: $customAmount)
            .foregroundColor(.white)
            .font(.system(size: 34, weight: .bold))
            .keyboardType(.decimalPad)
        }
        .padding()
        .background(Color.marketCard)
        .cornerRadius(CornerRadius.sm)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Quick amounts")
          .font(Typography.caption1)
          .foregroundColor(.marketTextSecondary)

        HStack {
          ForEach(quickAmounts, id: \.self) { amount in
            Button(action: {
              let base = customAmountValue ?? 0
              customAmount = String(format: "%.2f", base + amount)
            }) {
              Text("+\(String(format: "%.0f", amount))")
                .font(Typography.body)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
            }
          }
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        Text("Quantity")
          .font(Typography.caption1)
          .foregroundColor(.marketTextSecondary)

        HStack {
          Stepper(value: $customQuantity, in: 1...50) {
            Text("\(customQuantity) item\(customQuantity == 1 ? "" : "s")")
              .font(Typography.body)
              .foregroundColor(.white)
          }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(CornerRadius.sm)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Label")
          .font(Typography.caption1)
          .foregroundColor(.marketTextSecondary)

        TextField("e.g. Custom service, donation, tip", text: $customDescription)
          .foregroundColor(.white)
          .padding()
          .background(Color.marketCard)
          .cornerRadius(CornerRadius.sm)
      }

      Button(action: { addCustomAmount() }) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text("Add to cart")
            .fontWeight(.semibold)
        }
        .font(Typography.body)
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding()
        .background(canAddCustomAmount ? Color.marketBlue : Color.marketBlue.opacity(0.4))
        .cornerRadius(CornerRadius.sm)
      }
      .disabled(!canAddCustomAmount)
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .cornerRadius(CornerRadius.md)
    .overlay(
      RoundedRectangle(cornerRadius: CornerRadius.md)
        .stroke(Color.white.opacity(0.08), lineWidth: 1)
    )
    .padding(.horizontal, Spacing.sm)
  }

  private var customCartList: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Current cart")
            .font(Typography.headline)
            .foregroundColor(.white)
          Text("Adjust quantities or remove lines.")
            .font(Typography.caption1)
            .foregroundColor(.marketTextSecondary)
        }
        Spacer()
        Button(action: { salesVM.clearCart() }) {
          Text("Clear")
            .font(Typography.caption1)
            .foregroundColor(.marketBlue)
        }
      }

      ForEach(salesVM.cartItems) { item in
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
              .font(Typography.subheadline)
              .foregroundColor(.white)
            Text("\(profileVM.currencySymbol) \(String(format: "%.2f", item.price)) each")
              .font(Typography.caption1)
              .foregroundColor(.marketTextSecondary)
          }

          Spacer()

          HStack(spacing: 8) {
            Button(action: { salesVM.removeFromCart(item: item) }) {
              Image(systemName: "minus.circle.fill")
                .foregroundColor(.marketTextSecondary)
            }
            Text("x\(item.quantity)")
              .font(Typography.body)
              .foregroundColor(.white)
              .frame(minWidth: 32)
            Button(action: { salesVM.increaseQuantity(for: item) }) {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(.marketBlue)
            }
          }
        }
        .padding()
        .background(Color.marketCard)
        .cornerRadius(CornerRadius.sm)
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
    ScrollView {
      VStack(spacing: 20) {
        Capsule()
          .fill(Color.white.opacity(0.3))
          .frame(width: 40, height: 5)
          .padding(.top, 8)

        VStack(alignment: .leading, spacing: 16) {
          Text("Add custom line item")
            .font(Typography.title3)
            .foregroundColor(.white)
            .bold()

          VStack(alignment: .leading, spacing: 10) {
            Text("Amount")
              .font(Typography.caption1)
              .foregroundColor(.marketTextSecondary)

            HStack(spacing: 12) {
              Text(profileVM.currencySymbol)
                .foregroundColor(.marketTextSecondary)
                .font(.title2)
              TextField("0.00", text: $customAmount)
                .currencyInput(text: $customAmount)
                .foregroundColor(.white)
                .font(.system(size: 32, weight: .bold))
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(CornerRadius.sm)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Quick adds")
              .font(Typography.caption1)
              .foregroundColor(.marketTextSecondary)

            HStack {
              ForEach(quickAmounts, id: \.self) { amount in
                Button(action: {
                  let base = customAmountValue ?? 0
                  customAmount = String(format: "%.2f", base + amount)
                }) {
                  Text("+\(String(format: "%.0f", amount))")
                    .font(Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
              }
            }
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Quantity")
              .font(Typography.caption1)
              .foregroundColor(.marketTextSecondary)
            Stepper(value: $customQuantity, in: 1...50) {
              Text("\(customQuantity) item\(customQuantity == 1 ? "" : "s")")
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(CornerRadius.sm)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Label")
              .font(Typography.caption1)
              .foregroundColor(.marketTextSecondary)

            TextField("Give this line a name", text: $customDescription)
              .foregroundColor(.white)
              .padding()
              .background(Color.white.opacity(0.08))
              .cornerRadius(CornerRadius.sm)
          }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(CornerRadius.md)

        HStack(spacing: 12) {
          Button(action: {
            showingCustomAmount = false
            resetCustomAmountFields()
          }) {
            Text("Cancel")
              .font(Typography.body)
              .foregroundColor(.marketTextSecondary)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.white.opacity(0.08))
              .cornerRadius(CornerRadius.sm)
          }

          Button(action: { addCustomAmount(dismissSheet: true) }) {
            Text("Add to cart")
              .font(Typography.body)
              .bold()
              .foregroundColor(.black)
              .frame(maxWidth: .infinity)
              .padding()
              .background(canAddCustomAmount ? Color.marketBlue : Color.marketBlue.opacity(0.4))
              .cornerRadius(CornerRadius.sm)
          }
          .disabled(!canAddCustomAmount)
        }
      }
      .padding(24)
    }
    .background(Color.marketBlue.edgesIgnoringSafeArea(.all))
    .presentationDetents([.medium, .large])
  }

  private func addCustomAmount(dismissSheet: Bool = false) {
    guard let amount = customAmountValue, amount > 0 else { return }
    let name = customDescription.isEmpty ? "Custom Amount" : customDescription
    salesVM.addCustomAmount(
      name: name,
      price: amount,
      quantity: customQuantity
    )
    if dismissSheet {
      showingCustomAmount = false
    }
    resetCustomAmountFields()
  }

  private func resetCustomAmountFields() {
    customAmount = ""
    customDescription = ""
    customQuantity = 1
  }

  private func fetchActivities() async {
    do {
      let fetched = try await ActivityService.fetchRecent(limit: 20)
      activities = profileVM.useInventory ? fetched : fetched.filter { !$0.isProductActivity }
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
