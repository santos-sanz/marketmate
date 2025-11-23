import SwiftUI

struct AddCostView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @Environment(\.presentationMode) var presentationMode

  @State private var description = ""
  @State private var amount = ""
  @State private var category = ""
  @State private var isRecurrent = false

  var body: some View {
    NavigationView {
      ZStack {
        Color.marketBlack.edgesIgnoringSafeArea(.all)

        Form {
          Section(header: Text("Details").foregroundColor(.marketTextSecondary)) {
            TextField("Description", text: $description)
            TextField("Amount", text: $amount)
              .keyboardType(.decimalPad)
          }
          .listRowBackground(Color.marketCard)

          Section(header: Text("Category").foregroundColor(.marketTextSecondary)) {
            TextField("Category (Optional)", text: $category)
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
      .navigationTitle("New Cost")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.marketTextSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveCost()
          }
          .foregroundColor(.marketGreen)
          .disabled(description.isEmpty || amount.isEmpty)
        }
      }
    }
  }

  private func saveCost() {
    guard let amountValue = Double(amount) else { return }

    Task {
      await costsVM.addCost(
        description: description,
        amount: amountValue,
        category: category.isEmpty ? nil : category,
        isRecurrent: isRecurrent
      )
      presentationMode.wrappedValue.dismiss()
    }
  }
}
