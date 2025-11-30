import SwiftUI

struct AddProductView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var themeManager: ThemeManager

  var productToEdit: Product?

  @State private var name = ""
  @State private var price = ""
  @State private var cost = ""
  @State private var stock = ""
  @State private var categoryId: UUID?
  @State private var description = ""

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }
  private var fieldBackground: Color { themeManager.fieldBackground }

  init(productToEdit: Product? = nil) {
    self.productToEdit = productToEdit
    _name = State(initialValue: productToEdit?.name ?? "")
    _price = State(initialValue: productToEdit != nil ? String(productToEdit!.price) : "")
    _cost = State(initialValue: productToEdit?.cost != nil ? String(productToEdit!.cost!) : "")
    _stock = State(
      initialValue: productToEdit?.stockQuantity != nil ? String(productToEdit!.stockQuantity!) : ""
    )
    _categoryId = State(initialValue: productToEdit?.categoryId)
    _description = State(initialValue: productToEdit?.description ?? "")
  }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()
        .edgesIgnoringSafeArea(.all)

      Form {
        Section(header: Text("Details").foregroundColor(secondaryTextColor)) {
          TextField("", text: $name)
            .placeholder(when: name.isEmpty) {
              Text("Product Name").foregroundColor(secondaryTextColor)
            }
            .foregroundColor(textColor)
        }
        .listRowBackground(cardBackground)

        Section(header: Text("Pricing & Stock").foregroundColor(secondaryTextColor)) {
          TextField("", text: $price)
            .placeholder(when: price.isEmpty) {
              Text("\(profileVM.currencySymbol) Price").foregroundColor(secondaryTextColor)
            }
            .foregroundColor(textColor)
            .currencyInput(text: $price)

          TextField("", text: $stock)
            .placeholder(when: stock.isEmpty) {
              Text("Stock Quantity").foregroundColor(secondaryTextColor)
            }
            .foregroundColor(textColor)
            .keyboardType(.numberPad)
        }
        .listRowBackground(cardBackground)

        Section(header: Text("Additional Information").foregroundColor(secondaryTextColor)) {
          TextField("", text: $cost)
            .placeholder(when: cost.isEmpty) {
              Text("\(profileVM.currencySymbol) Cost (Optional)").foregroundColor(
                secondaryTextColor)
            }
            .foregroundColor(textColor)
            .currencyInput(text: $cost)

          CategoryPicker(
            selectedCategoryId: $categoryId,
            categories: inventoryVM.categories,
            onAddCategory: { newCategory in
              Task {
                await inventoryVM.addCategory(name: newCategory)
              }
            },
            title: "Category"
          )

          TextField("", text: $description)
            .placeholder(when: description.isEmpty) {
              Text("Description").foregroundColor(secondaryTextColor)
            }
            .foregroundColor(textColor)
        }
        .listRowBackground(cardBackground)
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(productToEdit == nil ? "New Product" : "Edit Product")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          saveProduct()
        }
        .foregroundColor(textColor)
        .disabled(name.isEmpty || price.isEmpty)
      }
    }
    .onAppear {
      Task {
        await inventoryVM.fetchCategories()
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
        updatedProduct.categoryId = categoryId
        updatedProduct.description = description.isEmpty ? nil : description

        await inventoryVM.updateProduct(updatedProduct)
      } else {
        await inventoryVM.addProduct(
          name: name,
          price: priceValue,
          cost: costValue,
          stock: stockValue,
          categoryId: categoryId,
          description: description.isEmpty ? nil : description
        )
      }
      presentationMode.wrappedValue.dismiss()
    }
  }
}
