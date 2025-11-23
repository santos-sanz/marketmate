import SwiftUI

struct CostDetailView: View {
  @EnvironmentObject var costsVM: CostsViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode
  
  let cost: Cost
  
  @State private var isEditing = false
  @State private var editedDescription: String
  @State private var editedAmount: String
  @State private var editedCategory: String
  @State private var showingDeleteAlert = false
  
  let categories = ["Rent", "Utilities", "Supplies", "Marketing", "Other"]
  
  init(cost: Cost) {
    self.cost = cost
    _editedDescription = State(initialValue: cost.description)
    _editedAmount = State(initialValue: String(format: "%.2f", cost.amount))
    _editedCategory = State(initialValue: cost.category ?? "Other")
  }
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.clear.revolutBackground()
        
        Form {
          Section(header: Text("Cost Information").foregroundColor(.white.opacity(0.7))) {
            if isEditing {
              TextField("Description", text: $editedDescription)
                .foregroundColor(.white)
              Picker("Category", selection: $editedCategory) {
                ForEach(categories, id: \.self) { category in
                  Text(category).tag(category)
                }
              }
            } else {
              HStack {
                Text("Description")
                  .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(cost.description)
                  .foregroundColor(.white)
              }
              if let category = cost.category {
                HStack {
                  Text("Category")
                    .foregroundColor(.white.opacity(0.7))
                  Spacer()
                  Text(category)
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
                TextField("0.00", text: $editedAmount)
                  .keyboardType(.decimalPad)
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
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
          }
          .foregroundColor(.white)
        }
        
        ToolbarItem(placement: .primaryAction) {
          if isEditing {
            Button("Save") {
              saveChanges()
            }
            .foregroundColor(.marketGreen)
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
  }
  
  private func saveChanges() {
    guard let amount = Double(editedAmount) else {
      return
    }
    
    let updatedCost = Cost(
      id: cost.id,
      userId: cost.userId,
      description: editedDescription,
      amount: amount,
      category: editedCategory,
      createdAt: cost.createdAt
    )
    
    Task {
      await costsVM.updateCost(updatedCost)
      presentationMode.wrappedValue.dismiss()
    }
  }
}
