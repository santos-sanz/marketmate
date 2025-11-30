import SwiftUI

struct EditSaleView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var themeManager: ThemeManager

  let sale: Sale

  @State private var paymentMethod: String
  @State private var notes: String
  @State private var items: [SaleItem]

  let paymentMethods = ["Cash", "Card", "Transfer", "Other"]
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

  init(sale: Sale) {
    self.sale = sale
    _paymentMethod = State(initialValue: sale.paymentMethod)
    _notes = State(initialValue: sale.notes ?? "")
    _items = State(initialValue: sale.items ?? [])
  }

  var totalAmount: Double {
    items.reduce(0) { $0 + ($1.priceAtSale * Double($1.quantity)) }
  }

  var body: some View {
    NavigationView {
      ZStack {
        Color.clear.revolutBackground()
          .edgesIgnoringSafeArea(.all)

        Form {
          // Items Section
          Section(header: Text("Items").foregroundColor(secondaryTextColor)) {
            ForEach($items) { $item in
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(item.productName)
                    .foregroundColor(textColor)
                    .font(.body)
                  Text("$\(String(format: "%.2f", item.priceAtSale)) each")
                    .foregroundColor(secondaryTextColor)
                    .font(.caption)
                }

                Spacer()

                // Quantity controls
                HStack(spacing: 12) {
                  Button(action: {
                    if item.quantity > 1 {
                      item.quantity -= 1
                    }
                  }) {
                    Image(systemName: "minus.circle.fill")
                      .foregroundColor(secondaryTextColor)
                      .font(.title3)
                  }

                  Text("\(item.quantity)")
                    .foregroundColor(textColor)
                    .font(.headline)
                    .frame(minWidth: 30)

                  Button(action: {
                    item.quantity += 1
                  }) {
                    Image(systemName: "plus.circle.fill")
                      .foregroundColor(secondaryTextColor)
                      .font(.title3)
                  }
                }
              }
              .padding(.vertical, 4)
            }
            .onDelete(perform: deleteItems)
          }
          .listRowBackground(cardBackground)

          // Total Section
          Section(header: Text("Total").foregroundColor(secondaryTextColor)) {
            HStack {
              Text("Total Amount")
                .foregroundColor(textColor)
              Spacer()
              Text("$\(String(format: "%.2f", totalAmount))")
                .foregroundColor(textColor)
                .font(.headline)
            }
          }
          .listRowBackground(cardBackground)

          // Payment Section
          Section(header: Text("Payment").foregroundColor(secondaryTextColor)) {
            Picker("Payment Method", selection: $paymentMethod) {
              ForEach(paymentMethods, id: \.self) { method in
                Text(method).tag(method)
              }
            }
            .pickerStyle(.menu)
            .accentColor(textColor)
          }
          .listRowBackground(cardBackground)

          // Notes Section
          Section(header: Text("Notes").foregroundColor(secondaryTextColor)) {
            TextField("", text: $notes)
              .placeholder(when: notes.isEmpty) {
                Text("Notes").foregroundColor(secondaryTextColor)
              }
              .foregroundColor(textColor)
          }
          .listRowBackground(cardBackground)
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Edit Sale")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveSale()
          }
          .foregroundColor(textColor)
          .disabled(items.isEmpty)
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(secondaryTextColor)
        }
      }
    }
  }

  private func deleteItems(at offsets: IndexSet) {
    items.remove(atOffsets: offsets)
  }

  private func saveSale() {
    Task {
      var updatedSale = sale
      updatedSale.paymentMethod = paymentMethod
      updatedSale.notes = notes.isEmpty ? nil : notes
      updatedSale.totalAmount = totalAmount

      await salesVM.updateSaleWithItems(updatedSale, updatedItems: items, inventoryVM: inventoryVM)
      dismiss()
    }
  }
}
