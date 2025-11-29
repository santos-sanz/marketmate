import SwiftUI

struct CategoryPicker: View {
  @Binding var selectedCategoryId: UUID?
  let categories: [Category]
  let onAddCategory: (String) -> Void
  let title: String

  @State private var isAddingNew = false
  @State private var newCategoryName = ""

  var selectedCategoryName: String {
    categories.first(where: { $0.id == selectedCategoryId })?.name ?? ""
  }

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text(title)
          .foregroundColor(.marketTextSecondary)
        Spacer()
        
        if isAddingNew {
           EmptyView()
        } else {
            Menu {
              ForEach(categories, id: \.id) { category in
                Button(action: {
                  selectedCategoryId = category.id
                }) {
                  HStack {
                    Text(category.name)
                    if selectedCategoryId == category.id {
                      Image(systemName: "checkmark")
                    }
                  }
                }
              }

              Divider()

              Button(action: {
                isAddingNew = true
                newCategoryName = ""
              }) {
                Label("Add New Category", systemImage: "plus")
              }
            } label: {
              HStack {
                Text(selectedCategoryName.isEmpty ? "Select" : selectedCategoryName)
                  .foregroundColor(.white)
                Image(systemName: "plus")
                  .font(.caption)
                  .foregroundColor(.marketTextSecondary)
              }
            }
        }
      }

      if isAddingNew {
        HStack(spacing: 10) {
          Button(action: {
            isAddingNew = false
            newCategoryName = ""
          }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.red)
              .font(.title2)
          }
          
          TextField("", text: $newCategoryName)
            .placeholder(when: newCategoryName.isEmpty) {
              Text("New Category Name").foregroundColor(Color.white.opacity(0.6))
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .submitLabel(.done)
            .onSubmit {
              addNewCategory()
            }

          Button(action: addNewCategory) {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
              .font(.title2)
          }
          .disabled(newCategoryName.isEmpty)
        }
      }
    }
  }

  private func addNewCategory() {
    guard !newCategoryName.isEmpty else { return }
    onAddCategory(newCategoryName)
    // Optimistic selection logic should be handled by parent or by observing categories updates
    // For now we rely on the parent refreshing the categories list and the new category appearing
    isAddingNew = false
    newCategoryName = ""
  }
}
