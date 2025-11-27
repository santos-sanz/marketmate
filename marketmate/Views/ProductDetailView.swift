import SwiftUI

struct ProductDetailView: View {
  @EnvironmentObject var inventoryVM: InventoryViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode

  let product: Product

  @State private var isEditing = false
  @State private var editedName: String
  @State private var editedDescription: String
  @State private var editedPrice: String
  @State private var editedCost: String
  @State private var editedStock: String
  @State private var showingDeleteAlert = false

  init(product: Product) {
    self.product = product
    _editedName = State(initialValue: product.name)
    _editedDescription = State(initialValue: product.description ?? "")
    _editedPrice = State(initialValue: String(format: "%.2f", product.price))
    _editedCost = State(initialValue: String(format: "%.2f", product.cost ?? 0.0))
    _editedStock = State(initialValue: String(product.stockQuantity ?? 0))
  }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      Form {
        Section(header: Text("Product Information").foregroundColor(.marketTextSecondary)) {
          if isEditing {
            TextField("Name", text: $editedName)
              .foregroundColor(.white)
            TextField("Description", text: $editedDescription)
              .foregroundColor(.white)
          } else {
            HStack {
              Text("Name")
                .foregroundColor(.marketTextSecondary)
              Spacer()
              Text(product.name)
                .foregroundColor(.white)
            }
            if let desc = product.description, !desc.isEmpty {
              HStack {
                Text("Description")
                  .foregroundColor(.marketTextSecondary)
                Spacer()
                Text(desc)
                  .foregroundColor(.white)
              }
            }
          }
        }
        .listRowBackground(Color.marketCard)

        Section(header: Text("Pricing").foregroundColor(.marketTextSecondary)) {
          if isEditing {
            HStack {
              Text("Price")
                .foregroundColor(.marketTextSecondary)
              Spacer()
              TextField("\(profileVM.currencySymbol) 0.00", text: $editedPrice)
                .currencyInput(text: $editedPrice)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
            }
            HStack {
              Text("Cost")
                .foregroundColor(.marketTextSecondary)
              Spacer()
              TextField("\(profileVM.currencySymbol) 0.00", text: $editedCost)
                .currencyInput(text: $editedCost)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
            }
          } else {
            HStack {
              Text("Price")
                .foregroundColor(.marketTextSecondary)
              Spacer()
              Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", product.price))")
                .foregroundColor(.white)
            }
            HStack {
              Text("Cost")
                .foregroundColor(.marketTextSecondary)
              Spacer()
              Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", product.cost ?? 0.0))")
                .foregroundColor(.white)
            }
          }
        }
        .listRowBackground(Color.marketCard)

        Section(header: Text("Inventory").foregroundColor(.marketTextSecondary)) {
          if isEditing {
            HStack {
              Text("Stock Quantity")
                .foregroundColor(.marketTextSecondary)
              Spacer()
              TextField("0", text: $editedStock)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
            }
          } else {
            HStack {
              Text("Stock Quantity")
                .foregroundColor(.marketTextSecondary)
              Spacer()
              Text("\(product.stockQuantity ?? 0)")
                .foregroundColor(.white)
            }
          }
        }
        .listRowBackground(Color.marketCard)

        Section {
          Button(action: { showingDeleteAlert = true }) {
            HStack {
              Spacer()
              Text("Delete Product")
                .foregroundColor(.marketRed)
                .bold()
              Spacer()
            }
          }
        }
        .listRowBackground(Color.marketCard)
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Product Details")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        if isEditing {
          Button("Save") {
            saveChanges()
          }
          .foregroundColor(.white)
        } else {
          Button("Edit") {
            isEditing = true
          }
          .foregroundColor(.white)
        }
      }
    }
    .alert("Delete Product", isPresented: $showingDeleteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        Task {
          await inventoryVM.deleteProduct(id: product.id)
          presentationMode.wrappedValue.dismiss()
        }
      }
    } message: {
      Text("Are you sure you want to delete '\(product.name)'? This action cannot be undone.")
    }
  }

  private func saveChanges() {
    guard let price = Double(editedPrice),
      let cost = Double(editedCost),
      let stock = Int(editedStock)
    else {
      return
    }

    let updatedProduct = Product(
      id: product.id,
      userId: product.userId,
      name: editedName,
      description: editedDescription.isEmpty ? nil : editedDescription,
      price: price,
      cost: cost,
      stockQuantity: stock,
      createdAt: product.createdAt
    )

    Task {
      await inventoryVM.updateProduct(updatedProduct)
      presentationMode.wrappedValue.dismiss()
    }
  }
}
