import SwiftUI

struct EditSaleView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var inventoryVM: InventoryViewModel

  let sale: Sale

  @State private var paymentMethod: String
  @State private var notes: String
  @State private var items: [SaleItem]

  let paymentMethods = ["Cash", "Card", "Transfer", "Other"]

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
          Section(header: Text("Items").foregroundColor(.marketTextSecondary)) {
            ForEach($items) { $item in
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(item.productName)
                    .foregroundColor(.white)
                    .font(.body)
                  Text("$\(String(format: "%.2f", item.priceAtSale)) each")
                    .foregroundColor(.marketTextSecondary)
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
                      .foregroundColor(.white.opacity(0.7))
                      .font(.title3)
                  }

                  Text("\(item.quantity)")
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(minWidth: 30)

                  Button(action: {
                    item.quantity += 1
                  }) {
                    Image(systemName: "plus.circle.fill")
                      .foregroundColor(.white.opacity(0.7))
                      .font(.title3)
                  }
                }
              }
              .padding(.vertical, 4)
            }
            .onDelete(perform: deleteItems)
          }
          .listRowBackground(Color.marketCard)

          // Total Section
          Section(header: Text("Total").foregroundColor(.marketTextSecondary)) {
            HStack {
              Text("Total Amount")
                .foregroundColor(.white)
              Spacer()
              Text("$\(String(format: "%.2f", totalAmount))")
                .foregroundColor(.white)
                .font(.headline)
            }
          }
          .listRowBackground(Color.marketCard)

          // Payment Section
          Section(header: Text("Payment").foregroundColor(.marketTextSecondary)) {
            Picker("Payment Method", selection: $paymentMethod) {
              ForEach(paymentMethods, id: \.self) { method in
                Text(method).tag(method)
              }
            }
            .pickerStyle(.menu)
            .accentColor(.white)
          }
          .listRowBackground(Color.marketCard)

          // Notes Section
          Section(header: Text("Notes").foregroundColor(.marketTextSecondary)) {
            TextField("", text: $notes)
              .placeholder(when: notes.isEmpty) {
                Text("Notes").foregroundColor(Color.white.opacity(0.6))
              }
              .foregroundColor(.white)
          }
          .listRowBackground(Color.marketCard)
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Edit Sale")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveSale()
          }
          .foregroundColor(.white)
          .disabled(items.isEmpty)
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.marketTextSecondary)
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
