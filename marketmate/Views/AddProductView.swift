import SwiftUI

struct AddProductView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @Environment(\.presentationMode) var presentationMode

  var productToEdit: Product?

  @State private var name = ""
  @State private var price = ""
  @State private var cost = ""
  @State private var stock = ""
  @State private var category = ""
  @State private var description = ""

  init(productToEdit: Product? = nil) {
    self.productToEdit = productToEdit
    _name = State(initialValue: productToEdit?.name ?? "")
    _price = State(initialValue: productToEdit != nil ? String(productToEdit!.price) : "")
    _cost = State(initialValue: productToEdit?.cost != nil ? String(productToEdit!.cost!) : "")
    _stock = State(
      initialValue: productToEdit?.stockQuantity != nil ? String(productToEdit!.stockQuantity!) : ""
    )
    _category = State(initialValue: productToEdit?.category ?? "")
    _description = State(initialValue: productToEdit?.description ?? "")
  }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()
        .edgesIgnoringSafeArea(.all)

      Form {
        Section(header: Text("Details").foregroundColor(.marketTextSecondary)) {
          TextField("", text: $name)
            .placeholder(when: name.isEmpty) {
              Text("Product Name").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)

          TextField("", text: $category)
            .placeholder(when: category.isEmpty) {
              Text("Category").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)

          TextField("", text: $description)
            .placeholder(when: description.isEmpty) {
              Text("Description").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
        }
        .listRowBackground(Color.marketCard)

        Section(header: Text("Pricing & Stock").foregroundColor(.marketTextSecondary)) {
          TextField("", text: $price)
            .placeholder(when: price.isEmpty) {
              Text("Price").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
            .keyboardType(.decimalPad)

          TextField("", text: $cost)
            .placeholder(when: cost.isEmpty) {
              Text("Cost (Optional)").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
            .keyboardType(.decimalPad)

          TextField("", text: $stock)
            .placeholder(when: stock.isEmpty) {
              Text("Stock Quantity").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
            .keyboardType(.numberPad)
        }
        .listRowBackground(Color.marketCard)
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(productToEdit == nil ? "New Product" : "Edit Product")
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          saveProduct()
        }
        .foregroundColor(.white)
        .disabled(name.isEmpty || price.isEmpty)
      }
    }
  }

  private func saveProduct() {
    guard let priceValue = Double(price) else { return }
    let costValue = Double(cost)
    let stockValue = Int(stock)

    Task {
      if let product = productToEdit {
        var updatedProduct = product
        updatedProduct.name = name
        updatedProduct.price = priceValue
        updatedProduct.cost = costValue
        updatedProduct.stockQuantity = stockValue
        updatedProduct.category = category.isEmpty ? nil : category
        updatedProduct.description = description.isEmpty ? nil : description

        await inventoryVM.updateProduct(updatedProduct)
      } else {
        await inventoryVM.addProduct(
          name: name,
          price: priceValue,
          cost: costValue,
          stock: stockValue,
          category: category.isEmpty ? nil : category,
          description: description.isEmpty ? nil : description
        )
      }
      presentationMode.wrappedValue.dismiss()
    }
  }
}
