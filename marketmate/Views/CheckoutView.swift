import SwiftUI

struct CheckoutView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var marketSession: MarketSessionManager
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode

  @State private var paymentMethod = "Cash"
  @State private var cashReceived = ""
  @State private var notes = ""
  @State private var source = "App"

  var changeDue: Double {
    guard let cash = Double(cashReceived) else { return 0 }
    return max(0, cash - salesVM.cartTotal)
  }

  let paymentMethods = ["Cash", "Card", "Transfer"]

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color.marketBlue,
          Color.marketDarkBlue,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack {
        List {
          Section(header: Text("Items").foregroundColor(.marketTextSecondary)) {
            ForEach(salesVM.cartItems) { item in
              HStack {
                Text("\(item.quantity) x \(item.product.name)")
                  .foregroundColor(.white)
                Spacer()
                Text(
                  "\(profileVM.currencySymbol) \(String(format: "%.2f", item.product.price * Double(item.quantity)))"
                )
                .foregroundColor(.white)
              }
              .listRowBackground(Color.marketCard)
            }
          }

          Section(header: Text("Payment").foregroundColor(.marketTextSecondary)) {
            Picker("Method", selection: $paymentMethod) {
              ForEach(paymentMethods, id: \.self) { method in
                Text(method).tag(method)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .listRowBackground(Color.marketCard)

            if paymentMethod == "Cash" {
              HStack {
                Text("Cash Received")
                  .foregroundColor(.white)
                Spacer()
                TextField("0.00", text: $cashReceived)
                  .keyboardType(.decimalPad)
                  .multilineTextAlignment(.trailing)
                  .foregroundColor(.white)
              }
              .listRowBackground(Color.marketCard)

              if !cashReceived.isEmpty {
                HStack {
                  Text("Change Due")
                    .font(Typography.headline)
                    .foregroundColor(.marketGreen)
                  Spacer()
                  Text("\(profileVM.currencySymbol) \(String(format: "%.2f", changeDue))")
                    .font(Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.marketGreen)
                }
                .listRowBackground(Color.marketCard)
              }
            }

            TextField("Notes", text: $notes)
              .listRowBackground(Color.marketCard)
              .foregroundColor(.white)
          }

          Section {
            HStack {
              Text("Total to Pay")
                .font(Typography.title2)
                .foregroundColor(.white)
              Spacer()
              Text("\(profileVM.currencySymbol) \(String(format: "%.2f", salesVM.cartTotal))")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.marketCard)
          }
        }
        .scrollContentBackground(.hidden)

        Button(action: confirmSale) {
          Text("Confirm Sale")
            .font(Typography.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.marketBlue)
            .cornerRadius(CornerRadius.xl)
        }
        .padding(Spacing.md)
      }
    }
    .navigationTitle("Checkout")
    .onAppear {
      print("🛒 [CheckoutView] onAppear called")
      print("🛒 [CheckoutView] Cart items: \(salesVM.cartItems.count)")
      print("🛒 [CheckoutView] Cart total: \(salesVM.cartTotal)")
      print("🛒 [CheckoutView] Active market: \(marketSession.activeMarket != nil ? "Yes" : "No")")
      if let error = salesVM.errorMessage {
        print("❌ [CheckoutView] SalesVM error: \(error)")
      }
    }
    .alert("Error", isPresented: .constant(salesVM.errorMessage != nil)) {
      Button("OK") {
        salesVM.errorMessage = nil
      }
    } message: {
      Text(salesVM.errorMessage ?? "")
    }
  }

  private func confirmSale() {
    print("Confirm sale pressed. Payment Method: \(paymentMethod), Total: \(salesVM.cartTotal)")
    let items = salesVM.cartItems.map { cartItem in
      SaleItem(
        id: UUID(),  // Placeholder, handled in VM
        saleId: UUID(),  // Placeholder
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        quantity: cartItem.quantity,
        priceAtSale: cartItem.product.price,
        costAtSale: cartItem.product.cost
      )
    }

    Task {
      await salesVM.createSale(
        items: items,
        total: salesVM.cartTotal,
        paymentMethod: paymentMethod,
        source: source,
        notes: notes.isEmpty ? nil : notes,
        marketId: marketSession.activeMarket?.id,
        marketLocation: marketSession.activeMarket?.location
      )
      salesVM.clearCart()
      presentationMode.wrappedValue.dismiss()
    }
  }
}
