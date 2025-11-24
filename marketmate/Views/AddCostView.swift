import SwiftUI

struct AddCostView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @Environment(\.presentationMode) var presentationMode

  var costToEdit: Cost?

  @State private var description = ""
  @State private var amount = ""
  @State private var category = ""
  @State private var isRecurrent = false

  init(costToEdit: Cost? = nil) {
    self.costToEdit = costToEdit
    _description = State(initialValue: costToEdit?.description ?? "")
    _amount = State(initialValue: costToEdit != nil ? String(costToEdit!.amount) : "")
    _category = State(initialValue: costToEdit?.category ?? "")
    _isRecurrent = State(initialValue: costToEdit?.isRecurrent ?? false)
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
              Text("Amount").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
            .keyboardType(.decimalPad)
        }
        .listRowBackground(Color.marketCard)

        Section(header: Text("Category").foregroundColor(.marketTextSecondary)) {
          TextField("", text: $category)
            .placeholder(when: category.isEmpty) {
              Text("Category (Optional)").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
          // TODO: Add category picker from costsVM.categories
        }
        .listRowBackground(Color.marketCard)

        Section {
          Toggle("Recurrent Cost", isOn: $isRecurrent)
        }
        .listRowBackground(Color.marketCard)
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(costToEdit == nil ? "New Cost" : "Edit Cost")
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
        updatedCost.category = category.isEmpty ? nil : category
        updatedCost.isRecurrent = isRecurrent

        await costsVM.updateCost(updatedCost)
      } else {
        await costsVM.addCost(
          description: description,
          amount: amountValue,
          category: category.isEmpty ? nil : category,
          isRecurrent: isRecurrent
        )
      }
      presentationMode.wrappedValue.dismiss()
    }
  }
}
