import CoreLocation
import SwiftUI

struct SalesView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var costsVM: CostsViewModel
  @StateObject private var marketSession = MarketSessionManager()
  @StateObject private var locationManager = LocationManager()
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var themeManager: ThemeManager

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

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var fieldBackground: Color { themeManager.fieldBackground }
  private var strokeColor: Color { themeManager.strokeColor }

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
          .foregroundColor(secondaryTextColor)
      }

      if profileVM.useInventory {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(secondaryTextColor)
          TextField("Search", text: $searchText)
            .foregroundColor(textColor)
            .accentColor(textColor)
            .placeholder(when: searchText.isEmpty) {
              Text("Search").foregroundColor(secondaryTextColor)
            }
        }
        .searchBarStyle(themeManager: themeManager)
      } else {
        VStack(alignment: .leading, spacing: 2) {
          Text("Custom Sales")
            .font(Typography.subheadline)
            .foregroundColor(textColor)
          Text("Inventory features hidden")
            .font(Typography.caption1)
            .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      Button(action: {
        locationManager.requestPermission()
        locationManager.startUpdatingLocation()
        showingStartMarket = true
      }) {
        Image(systemName: "tent.fill")
          .foregroundColor(textColor)
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
        .foregroundColor(textColor)
      Text("Open Market: \(market.location ?? "Unknown")")
        .font(.headline)
        .foregroundColor(textColor)
      Spacer()
      Button(action: { Task { await marketSession.endMarket() } }) {
        Text("End")
          .font(.caption)
          .bold()
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(themeManager.translucentOverlay)
          .foregroundColor(textColor)
          .cornerRadius(12)
      }
    }
    .padding()
    .background(cardBackground)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(strokeColor, lineWidth: 1)
    )
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
                  .foregroundColor(textColor)
                Text("Custom")
                  .font(Typography.caption1)
                  .foregroundColor(textColor)
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(fieldBackground)
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
          .foregroundColor(textColor)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity)
          .background(themeManager.translucentOverlay)
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
            .foregroundColor(textColor)
          Text("Build a sale without inventory items.")
            .font(Typography.caption1)
            .foregroundColor(secondaryTextColor)
        }
        Spacer()
        Text("Inventory off")
          .font(Typography.caption1)
          .foregroundColor(textColor)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(themeManager.translucentOverlay)
          .cornerRadius(20)
      }

      VStack(alignment: .leading, spacing: 12) {
        Text("Amount")
          .font(Typography.caption1)
          .foregroundColor(textColor)

        HStack(spacing: 12) {
          Text(profileVM.currencySymbol)
            .foregroundColor(secondaryTextColor)
            .font(.title2)
          TextField("0.00", text: $customAmount)
            .currencyInput(text: $customAmount)
            .foregroundColor(textColor)
            .font(.system(size: 34, weight: .bold))
            .keyboardType(.decimalPad)
        }
        .padding()
        .background(fieldBackground)
        .cornerRadius(CornerRadius.sm)
      }

      HStack {
        Text("Quantity")
          .font(Typography.caption1)
          .foregroundColor(textColor)

        Spacer()

        HStack(spacing: 16) {
          Button(action: {
            if customQuantity > 1 { customQuantity -= 1 }
          }) {
            Image(systemName: "minus.circle.fill")
              .foregroundColor(secondaryTextColor)
              .font(.title3)
          }

          Text("\(customQuantity)")
            .font(Typography.body.weight(.semibold))
            .foregroundColor(textColor)
            .frame(minWidth: 20)

          Button(action: {
            customQuantity += 1
          }) {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(textColor)
              .font(.title3)
          }
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Label")
          .font(Typography.caption1)
          .foregroundColor(textColor)

        TextField("e.g. Custom service, donation, tip", text: $customDescription)
          .foregroundColor(textColor)
          .padding()
          .background(fieldBackground)
          .cornerRadius(CornerRadius.sm)
      }

      Button(action: { addCustomAmount() }) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text("Add to cart")
            .fontWeight(.semibold)
        }
        .font(Typography.body)
        .foregroundColor(textColor)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
          (canAddCustomAmount
            ? themeManager.primaryTextColor.opacity(0.16)
            : themeManager.primaryTextColor.opacity(0.08))
        )
        .cornerRadius(CornerRadius.sm)
      }
      .disabled(!canAddCustomAmount)
    }
    .padding()
    .background(cardBackground)
    .cornerRadius(CornerRadius.md)
    .overlay(
      RoundedRectangle(cornerRadius: CornerRadius.md)
        .stroke(strokeColor, lineWidth: 1)
    )
    .padding(.horizontal, Spacing.sm)
  }

  private var customCartList: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Current cart")
            .font(Typography.headline)
            .foregroundColor(textColor)
          Text("Adjust quantities or remove lines.")
            .font(Typography.caption1)
            .foregroundColor(secondaryTextColor)
        }
        Spacer()
        Button(action: { salesVM.clearCart() }) {
          Text("Clear")
            .font(Typography.caption1)
            .foregroundColor(secondaryTextColor)
        }
      }

      ForEach(salesVM.cartItems) { item in
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
              .font(Typography.subheadline)
              .foregroundColor(textColor)
            Text("\(profileVM.currencySymbol) \(String(format: "%.2f", item.price)) each")
              .font(Typography.caption1)
              .foregroundColor(secondaryTextColor)
          }

          Spacer()

          HStack(spacing: 8) {
            Button(action: { salesVM.removeFromCart(item: item) }) {
              Image(systemName: "minus.circle.fill")
                .foregroundColor(secondaryTextColor)
            }
            Text("x\(item.quantity)")
              .font(Typography.body)
              .foregroundColor(textColor)
              .frame(minWidth: 32)
            Button(action: { salesVM.increaseQuantity(for: item) }) {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(textColor)
            }
          }
        }
        .padding()
        .background(cardBackground)
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
          .foregroundColor(textColor)
        Spacer()
        NavigationLink(
          destination: ActivityHistoryView(initialFilter: .sales).environmentObject(profileVM)
        ) {
          Text("Show all")
            .font(.subheadline)
            .foregroundColor(textColor)
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
            .foregroundColor(textColor.opacity(0.8))

          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("Total")
              .font(.subheadline)
              .foregroundColor(textColor.opacity(0.8))

            Text("\(profileVM.currencySymbol) \(String(format: "%.2f", salesVM.cartTotal))")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(textColor)
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
          .foregroundColor(textColor)
          .padding(.vertical, 12)
          .padding(.horizontal, 20)
          .background(cardBackground)
          .cornerRadius(30)
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
      .padding(.bottom, 8)
    }
    .background(
      Rectangle()
        .fill(themeManager.elevatedCardBackground)
        .overlay(themeManager.translucentOverlay)
    )
    .cornerRadius(24, corners: [.topLeft, .topRight])
    .shadow(color: strokeColor, radius: 10, x: 0, y: -5)
  }

  private var customAmountSheet: some View {
    ScrollView {
      VStack(spacing: 20) {
        Capsule()
          .fill(themeManager.translucentOverlay)
          .frame(width: 40, height: 5)
          .padding(.top, 8)

        VStack(alignment: .leading, spacing: 16) {
          Text("Add custom line item")
            .font(Typography.title3)
            .foregroundColor(textColor)
            .bold()

          VStack(alignment: .leading, spacing: 10) {
            Text("Amount")
              .font(Typography.caption1)
              .foregroundColor(secondaryTextColor)

            HStack(spacing: 12) {
              Text(profileVM.currencySymbol)
                .foregroundColor(secondaryTextColor)
                .font(.title2)
              TextField("0.00", text: $customAmount)
                .currencyInput(text: $customAmount)
                .foregroundColor(textColor)
                .font(.system(size: 32, weight: .bold))
            }
            .padding()
            .background(fieldBackground)
            .cornerRadius(CornerRadius.sm)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Quick adds")
              .font(Typography.caption1)
              .foregroundColor(secondaryTextColor)

            HStack {
              ForEach(quickAmounts, id: \.self) { amount in
                Button(action: {
                  let base = customAmountValue ?? 0
                  customAmount = String(format: "%.2f", base + amount)
                }) {
                  Text("+\(String(format: "%.0f", amount))")
                    .font(Typography.body)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(themeManager.translucentOverlay)
                    .cornerRadius(12)
                }
              }
            }
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Quantity")
              .font(Typography.caption1)
              .foregroundColor(secondaryTextColor)
            Stepper(value: $customQuantity, in: 1...50) {
              Text("\(customQuantity) item\(customQuantity == 1 ? "" : "s")")
                .foregroundColor(textColor)
            }
            .padding()
            .background(fieldBackground)
            .cornerRadius(CornerRadius.sm)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Label")
              .font(Typography.caption1)
              .foregroundColor(secondaryTextColor)

            TextField("Give this line a name", text: $customDescription)
              .foregroundColor(textColor)
              .padding()
              .background(fieldBackground)
              .cornerRadius(CornerRadius.sm)
          }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(CornerRadius.md)

        HStack(spacing: 12) {
          Button(action: {
            showingCustomAmount = false
            resetCustomAmountFields()
          }) {
            Text("Cancel")
              .font(Typography.body)
              .foregroundColor(secondaryTextColor)
              .frame(maxWidth: .infinity)
              .padding()
              .background(fieldBackground)
              .cornerRadius(CornerRadius.sm)
          }

          Button(action: { addCustomAmount(dismissSheet: true) }) {
            Text("Add to cart")
              .font(Typography.body)
              .bold()
              .foregroundColor(textColor)
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                canAddCustomAmount
                  ? themeManager.primaryTextColor.opacity(0.16)
                  : themeManager.primaryTextColor.opacity(0.08)
              )
              .cornerRadius(CornerRadius.sm)
          }
          .disabled(!canAddCustomAmount)
        }
      }
      .padding(24)
    }
    .background(themeManager.backgroundColor.edgesIgnoringSafeArea(.all))
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
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 0) {
        Text(product.name)
          .font(Typography.subheadline)
          .foregroundColor(themeManager.primaryTextColor)
          .lineLimit(2)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer()

        Text("\(profileVM.currencySymbol) \(String(format: "%.2f", product.price))")
          .font(Typography.headline)
          .fontWeight(.bold)
          .foregroundColor(themeManager.primaryTextColor)
      }

      .padding(Spacing.sm)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(themeManager.cardBackground)
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
