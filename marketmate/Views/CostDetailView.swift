import SwiftUI

struct CostDetailView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode

  let cost: Cost

  @State private var isEditing = false
  @State private var editedDescription: String
  @State private var editedAmount: String
  @State private var editedCategoryId: UUID?
  @State private var showingDeleteAlert = false

  init(cost: Cost) {
    self.cost = cost
    _editedDescription = State(initialValue: cost.description)
    _editedAmount = State(initialValue: String(format: "%.2f", cost.amount))
    _editedCategoryId = State(initialValue: cost.categoryId)
  }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      Form {
        Section(header: Text("Cost Information").foregroundColor(.white.opacity(0.7))) {
          if isEditing {
            TextField("Description", text: $editedDescription)
              .foregroundColor(.white)

            CategoryPicker(
              selectedCategoryId: $editedCategoryId,
              categories: costsVM.categories,
              onAddCategory: { newCategory in
                Task {
                  await costsVM.addCategory(name: newCategory)
                }
              },
              title: "Category"
            )
          } else {
            HStack {
              Text("Description")
                .foregroundColor(.white.opacity(0.7))
              Spacer()
              Text(cost.description)
                .foregroundColor(.white)
            }
            if let categoryId = cost.categoryId,
              let categoryName = costsVM.categories.first(where: { $0.id == categoryId })?.name
            {
              HStack {
                Text("Category")
                  .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(categoryName)
                  .foregroundColor(.white)
              }
            }
          }
        }
        .listRowBackground(Color.white.opacity(0.15))

        Section(header: Text("Amount").foregroundColor(.white.opacity(0.7))) {
          if isEditing {
            HStack {
              Text("Amount")
                .foregroundColor(.white.opacity(0.7))
              Spacer()
              TextField("\(profileVM.currencySymbol) 0.00", text: $editedAmount)
                .currencyInput(text: $editedAmount)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
            }
          } else {
            HStack {
              Text("Amount")
                .foregroundColor(.white.opacity(0.7))
              Spacer()
              Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", cost.amount))")
                .foregroundColor(.white)
            }
          }
        }
        .listRowBackground(Color.white.opacity(0.15))

        Section(header: Text("Date").foregroundColor(.white.opacity(0.7))) {
          HStack {
            Text("Created")
              .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(cost.createdAt.formatted(date: .abbreviated, time: .shortened))
              .foregroundColor(.white)
          }
        }
        .listRowBackground(Color.white.opacity(0.15))

        Section {
          Button(action: { showingDeleteAlert = true }) {
            HStack {
              Spacer()
              Text("Delete Cost")
                .foregroundColor(.red)
                .bold()
              Spacer()
            }
          }
        }
        .listRowBackground(Color.white.opacity(0.15))
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Cost Details")
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
    .alert("Delete Cost", isPresented: $showingDeleteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        Task {
          await costsVM.deleteCost(id: cost.id)
          presentationMode.wrappedValue.dismiss()
        }
      }
    } message: {
      Text("Are you sure you want to delete this cost? This action cannot be undone.")
    }
  }

  private func saveChanges() {
    guard let amount = Double(editedAmount) else {
      return
    }

    let updatedCost = Cost(
      id: cost.id,
      userId: cost.userId,
      marketId: cost.marketId,
      description: editedDescription,
      amount: amount,
      categoryId: editedCategoryId,
      isRecurrent: cost.isRecurrent,
      createdAt: cost.createdAt
    )

    Task {
      await costsVM.updateCost(updatedCost)
      presentationMode.wrappedValue.dismiss()
    }
  }
}
