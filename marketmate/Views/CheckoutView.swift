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

  // Discount State
  @State private var discountValue = ""
  @State private var isPercentage = false
  @State private var isDiscountExpanded = false

  var discountAmount: Double {
    guard let value = Double(discountValue) else { return 0 }
    if isPercentage {
      return salesVM.cartTotal * (value / 100)
    } else {
      return value
    }
  }

  var finalTotal: Double {
    max(0, salesVM.cartTotal - discountAmount)
  }

  var changeDue: Double {
    guard let cash = Double(cashReceived) else { return 0 }
    return max(0, cash - finalTotal)
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
          Section(header: Text("Items").foregroundColor(.white).bold()) {
            ForEach(salesVM.cartItems) { item in
              HStack {
                Text("\(item.quantity) x \(item.name)")
                  .foregroundColor(.white)
                  .fontWeight(.medium)
                Spacer()
                Text(
                  "\(profileVM.currencySymbol) \(String(format: "%.2f", item.price * Double(item.quantity)))"
                )
                .foregroundColor(.white)
                .fontWeight(.bold)
              }
              .listRowBackground(Color.white.opacity(0.2))
            }
          }

          Section(header: Text("Payment").foregroundColor(.white).bold()) {
            Picker("Method", selection: $paymentMethod) {
              ForEach(paymentMethods, id: \.self) { method in
                Text(method).tag(method)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .listRowBackground(Color.white.opacity(0.2))

            if paymentMethod == "Cash" {
              HStack {
                Text("Cash Received")
                  .foregroundColor(.white)
                  .fontWeight(.medium)
                Spacer()
                TextField("", text: $cashReceived)
                  .placeholder(when: cashReceived.isEmpty, alignment: .trailing) {
                    Text("\(profileVM.currencySymbol) 0.00").foregroundColor(.white.opacity(0.5))
                  }
                  .currencyInput(text: $cashReceived)
                  .multilineTextAlignment(.trailing)
                  .foregroundColor(.white)
                  .font(.title3)
              }
              .listRowBackground(Color.white.opacity(0.2))

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
                .listRowBackground(Color.white.opacity(0.2))
              }
            }

            TextField("", text: $notes)
              .placeholder(when: notes.isEmpty) {
                Text("Notes").foregroundColor(.white.opacity(0.5))
              }
              .listRowBackground(Color.white.opacity(0.2))
              .foregroundColor(.white)
          }

          Section(
            header:
              HStack {
                Text("Discount")
                  .foregroundColor(.white)
                  .bold()
                Spacer()
                Button(action: {
                  withAnimation {
                    isDiscountExpanded.toggle()
                  }
                }) {
                  Image(systemName: isDiscountExpanded ? "minus.circle.fill" : "plus.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
                }
              }
          ) {
            if isDiscountExpanded {
              HStack {
                TextField("", text: $discountValue)
                  .placeholder(when: discountValue.isEmpty) {
                    Text("\(profileVM.currencySymbol) Discount").foregroundColor(
                      .white.opacity(0.5))
                  }
                  .currencyInput(text: $discountValue)
                  .foregroundColor(.white)

                Picker("Type", selection: $isPercentage) {
                  Text(profileVM.currencySymbol).tag(false)
                  Text("%").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)
              }
              .listRowBackground(Color.white.opacity(0.2))

              if discountAmount > 0 {
                HStack {
                  Text("Discount Applied")
                    .foregroundColor(.marketGreen)
                  Spacer()
                  Text("- \(profileVM.currencySymbol) \(String(format: "%.2f", discountAmount))")
                    .foregroundColor(.marketGreen)
                }
                .listRowBackground(Color.white.opacity(0.2))
              }
            }
          }

          Section {
            HStack {
              Text("Subtotal")
                .foregroundColor(.white.opacity(0.9))
                .fontWeight(.medium)
              Spacer()
              Text("\(profileVM.currencySymbol) \(String(format: "%.2f", salesVM.cartTotal))")
                .foregroundColor(.white.opacity(0.9))
                .fontWeight(.medium)
            }
            .listRowBackground(Color.white.opacity(0.2))

            HStack {
              Text("Total to Pay")
                .font(Typography.title2)
                .bold()
                .foregroundColor(.white)
              Spacer()
              Text("\(profileVM.currencySymbol) \(String(format: "%.2f", finalTotal))")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.white.opacity(0.2))
          }
        }
        .scrollContentBackground(.hidden)

        Button(action: confirmSale) {
          Text("Confirm Sale")
            .font(Typography.headline)
            .fontWeight(.semibold)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.white)
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
    print("Confirm sale pressed. Payment Method: \(paymentMethod), Total: \(finalTotal)")
    var items = salesVM.cartItems.map { cartItem in
      SaleItem(
        id: UUID(),  // Placeholder, handled in VM
        saleId: UUID(),  // Placeholder
        productId: cartItem.product?.id,
        productName: cartItem.name,
        quantity: cartItem.quantity,
        priceAtSale: cartItem.price,
        costAtSale: cartItem.product?.cost
      )
    }

    // Add discount as a negative line item if applicable
    if discountAmount > 0 {
      let discountItem = SaleItem(
        id: UUID(),
        saleId: UUID(),
        productId: nil,
        productName: "Discount",
        quantity: 1,
        priceAtSale: -discountAmount,
        costAtSale: nil
      )
      items.append(discountItem)
    }

    Task {
      await salesVM.createSale(
        items: items,
        total: finalTotal,
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
