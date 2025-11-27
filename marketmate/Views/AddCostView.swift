import SwiftUI

struct AddCostView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode

  var costToEdit: Cost?

  @State private var description = ""
  @State private var amount = ""
  @State private var categoryId: UUID?

  init(costToEdit: Cost? = nil) {
    self.costToEdit = costToEdit
    _description = State(initialValue: costToEdit?.description ?? "")
    _amount = State(initialValue: costToEdit != nil ? String(costToEdit!.amount) : "")
    _categoryId = State(initialValue: costToEdit?.categoryId)
  }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()
        .edgesIgnoringSafeArea(.all)

      Form {
        Section(header: Text("Details").foregroundColor(.marketTextSecondary)) {
          TextField("", text: $description)
            .placeholder(when: description.isEmpty) {
              Text("Description").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)

          TextField("", text: $amount)
            .placeholder(when: amount.isEmpty) {
              Text("\(profileVM.currencySymbol) Amount").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
            .currencyInput(text: $amount)
        }
        .listRowBackground(Color.marketCard)

        Section(header: Text("Category").foregroundColor(.marketTextSecondary)) {
          CategoryPicker(
            selectedCategoryId: $categoryId,
            categories: costsVM.categories.map {
              Category(
                id: $0.id, userId: $0.userId, name: $0.name, type: .cost, createdAt: $0.createdAt)
            },  // Adapter
            onAddCategory: { newCategory in
              Task {
                await costsVM.addCategory(name: newCategory)
              }
            },
            title: "Category"
          )
        }
        .listRowBackground(Color.marketCard)
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(costToEdit == nil ? "New Cost" : "Edit Cost")
    .onAppear {
      Task {
        await costsVM.fetchCategories()
      }
    }
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          saveCost()
        }
        .foregroundColor(.white)
        .disabled(description.isEmpty || amount.isEmpty)
      }
    }
  }

  private func saveCost() {
    guard let amountValue = Double(amount) else { return }

    Task {
      if let cost = costToEdit {
        var updatedCost = cost
        updatedCost.description = description
        updatedCost.amount = amountValue
        updatedCost.categoryId = categoryId

        await costsVM.updateCost(updatedCost)
      } else {
        await costsVM.addCost(
          description: description,
          amount: amountValue,
          categoryId: categoryId
        )
      }
      presentationMode.wrappedValue.dismiss()
    }
  }
}
