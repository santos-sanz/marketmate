import SwiftUI

struct SaleDetailView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var themeManager: ThemeManager

  let sale: Sale
  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      List {
        Section(header: Text("Sale Information").foregroundColor(secondaryTextColor)) {
          HStack {
            Text("Date")
              .foregroundColor(secondaryTextColor)
            Spacer()
            Text(sale.createdAt.formatted(date: .abbreviated, time: .shortened))
              .foregroundColor(textColor)
          }

          HStack {
            Text("Payment Method")
              .foregroundColor(secondaryTextColor)
            Spacer()
            Text(sale.paymentMethod)
              .foregroundColor(textColor)
          }

          if let location = sale.marketLocation {
            HStack {
              Text("Location")
                .foregroundColor(secondaryTextColor)
              Spacer()
              Text(location)
                .foregroundColor(textColor)
            }
          }
        }
        .listRowBackground(cardBackground)

        Section(header: Text("Items").foregroundColor(secondaryTextColor)) {
          if let items = sale.items {
            ForEach(items) { item in
              HStack {
                Text("\(item.quantity)x \(item.productName)")
                  .foregroundColor(textColor)
                Spacer()
                Text(
                  "\(profileVM.selectedCurrency) \(String(format: "%.2f", item.priceAtSale * Double(item.quantity)))"
                )
                .foregroundColor(textColor)
              }
            }
          } else {
            Text("No items")
              .foregroundColor(secondaryTextColor)
          }
        }
        .listRowBackground(cardBackground)

        Section(header: Text("Total").foregroundColor(secondaryTextColor)) {
          HStack {
            Text("Total Amount")
              .foregroundColor(secondaryTextColor)
            Spacer()
            Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", sale.totalAmount))")
              .font(.headline)
              .foregroundColor(textColor)
          }
        }
        .listRowBackground(cardBackground)
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Sale Details")
    .navigationBarTitleDisplayMode(.inline)
  }
}
