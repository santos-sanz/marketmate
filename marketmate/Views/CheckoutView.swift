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
    NavigationView {
      ZStack {
        Color.clear.revolutBackground()

        VStack {
          List {
            Section(header: Text("Items").foregroundColor(.marketTextSecondary)) {
              ForEach(salesVM.cartItems) { item in
                HStack {
                  Text("\(item.quantity) x \(item.product.name)")
                    .foregroundColor(.white)
                  Spacer()
                  Text(
                    "\(profileVM.selectedCurrency) \(String(format: "%.2f", item.product.price * Double(item.quantity)))"
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
                    Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", changeDue))")
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
                  .font(Typography.title3)
                  .foregroundColor(.white)
                Spacer()
                Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", salesVM.cartTotal))")
                  .font(Typography.display)
                  .fontWeight(.bold)
                  .foregroundColor(.white)
              }
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
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.marketTextSecondary)
        }
      }
    }
  }

  private func confirmSale() {
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
        marketId: marketSession.activeMarket?.id
      )
      salesVM.clearCart()
      presentationMode.wrappedValue.dismiss()
    }
  }
}
