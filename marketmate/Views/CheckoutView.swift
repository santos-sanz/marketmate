import SwiftUI

struct CheckoutView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var marketSession: MarketSessionManager
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var themeManager: ThemeManager

  @State private var paymentMethod = "Cash"
  @State private var cashReceived = ""
  @State private var notes = ""
  @State private var source = "App"

  // Discount State
  @State private var discountValue = ""
  @State private var isPercentage = false
  @State private var isDiscountExpanded = false
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var fieldBackground: Color { themeManager.fieldBackground }
  private var strokeColor: Color { themeManager.strokeColor }

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
      Color.clear.revolutBackground()

      VStack {
        List {
          Section(header: Text("Items").foregroundColor(textColor).bold()) {
            ForEach(salesVM.cartItems) { item in
              HStack {
                Text("\(item.quantity) x \(item.name)")
                  .foregroundColor(textColor)
                  .fontWeight(.medium)
                Spacer()
                Text(
                  "\(profileVM.currencySymbol) \(String(format: "%.2f", item.price * Double(item.quantity)))"
                )
                .foregroundColor(textColor)
                .fontWeight(.bold)
              }
              .listRowBackground(cardBackground)
            }
          }

          Section(header: Text("Payment").foregroundColor(textColor).bold()) {
            Picker("Method", selection: $paymentMethod) {
              ForEach(paymentMethods, id: \.self) { method in
                Text(method).tag(method)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .listRowBackground(cardBackground)

            if paymentMethod == "Cash" {
              HStack {
                Text("Cash Received")
                  .foregroundColor(textColor)
                  .fontWeight(.medium)
                Spacer()
                TextField("", text: $cashReceived)
                  .placeholder(when: cashReceived.isEmpty, alignment: .trailing) {
                    Text("\(profileVM.currencySymbol) 0.00").foregroundColor(secondaryTextColor)
                  }
                  .currencyInput(text: $cashReceived)
                  .multilineTextAlignment(.trailing)
                  .foregroundColor(textColor)
                  .font(.title3)
              }
              .listRowBackground(cardBackground)

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
                .listRowBackground(cardBackground)
              }
            }

            TextField("", text: $notes)
              .placeholder(when: notes.isEmpty) {
                Text("Notes").foregroundColor(secondaryTextColor)
              }
              .listRowBackground(cardBackground)
              .foregroundColor(textColor)
          }

          Section(
            header:
              HStack {
                Text("Discount")
                  .foregroundColor(textColor)
                  .bold()
                Spacer()
                Button(action: {
                  isDiscountExpanded.toggle()
                }) {
                  Image(systemName: isDiscountExpanded ? "minus.circle.fill" : "plus.circle.fill")
                    .foregroundColor(textColor)
                    .font(.title3)
                }
              }
          ) {
            if isDiscountExpanded {
              HStack {
                TextField("", text: $discountValue)
                  .placeholder(when: discountValue.isEmpty) {
                    Text("\(profileVM.currencySymbol) Discount").foregroundColor(
                      secondaryTextColor)
                  }
                  .currencyInput(text: $discountValue)
                  .foregroundColor(textColor)

                Picker("Type", selection: $isPercentage) {
                  Text(profileVM.currencySymbol).tag(false)
                  Text("%").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 100)
              }
              .listRowBackground(cardBackground)

              if discountAmount > 0 {
                HStack {
                  Text("Discount Applied")
                    .foregroundColor(.marketGreen)
                  Spacer()
                  Text("- \(profileVM.currencySymbol) \(String(format: "%.2f", discountAmount))")
                    .foregroundColor(.marketGreen)
                }
                .listRowBackground(cardBackground)
              }
            }
          }

          Section {
            HStack {
              Text("Subtotal")
                .foregroundColor(textColor.opacity(0.9))
                .fontWeight(.medium)
              Spacer()
              Text("\(profileVM.currencySymbol) \(String(format: "%.2f", salesVM.cartTotal))")
                .foregroundColor(textColor.opacity(0.9))
                .fontWeight(.medium)
            }
            .listRowBackground(cardBackground)

            HStack {
              Text("Total to Pay")
                .font(Typography.title2)
                .bold()
                .foregroundColor(textColor)
              Spacer()
              Text("\(profileVM.currencySymbol) \(String(format: "%.2f", finalTotal))")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(textColor)
            }
            .padding(.vertical, 8)
            .listRowBackground(cardBackground)
          }
        }
        .scrollContentBackground(.hidden)

        Button(action: confirmSale) {
          Text("Confirm Sale")
            .font(Typography.headline)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(cardBackground)
            .overlay(
              RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(strokeColor, lineWidth: 1)
            )
            .cornerRadius(CornerRadius.xl)
        }
        .padding(Spacing.md)
      }
    }
    .navigationTitle("Checkout")
    .alert("Error", isPresented: .constant(salesVM.errorMessage != nil)) {
      Button("OK") {
        salesVM.errorMessage = nil
      }
    } message: {
      Text(salesVM.errorMessage ?? "")
    }
  }

  private func confirmSale() {
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
      dismiss()
    }
  }
}
