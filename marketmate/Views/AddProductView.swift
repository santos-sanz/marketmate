import SwiftUI

struct AddProductView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @Environment(\.presentationMode) var presentationMode

  @State private var name = ""
  @State private var price = ""
  @State private var cost = ""
  @State private var stock = ""
  @State private var category = ""
  @State private var description = ""

  var body: some View {
    NavigationView {
      ZStack {
        Color.marketBlack.edgesIgnoringSafeArea(.all)

        Form {
          Section(header: Text("Details").foregroundColor(.marketTextSecondary)) {
            TextField("Product Name", text: $name)
            TextField("Category", text: $category)
            TextField("Description", text: $description)
          }
          .listRowBackground(Color.marketCard)

          Section(header: Text("Pricing & Stock").foregroundColor(.marketTextSecondary)) {
            TextField("Price", text: $price)
              .keyboardType(.decimalPad)
            TextField("Cost (Optional)", text: $cost)
              .keyboardType(.decimalPad)
            TextField("Stock Quantity", text: $stock)
              .keyboardType(.numberPad)
          }
          .listRowBackground(Color.marketCard)
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("New Product")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.marketTextSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveProduct()
          }
          .foregroundColor(.marketGreen)
          .disabled(name.isEmpty || price.isEmpty)
        }
      }
    }
  }

  private func saveProduct() {
    guard let priceValue = Double(price) else { return }
    let costValue = Double(cost)
    let stockValue = Int(stock)

    Task {
      await inventoryVM.addProduct(
        name: name,
        price: priceValue,
        cost: costValue,
        stock: stockValue,
        category: category.isEmpty ? nil : category,
        description: description.isEmpty ? nil : description
      )
      presentationMode.wrappedValue.dismiss()
    }
  }
}
