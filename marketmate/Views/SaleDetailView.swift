import SwiftUI

struct SaleDetailView: View {
  @EnvironmentObject var salesVM: SalesViewModel
  @EnvironmentObject var profileVM: ProfileViewModel
  @Environment(\.presentationMode) var presentationMode

  let sale: Sale

  var body: some View {
    ZStack {
      Color.clear.revolutBackground()

      List {
        Section(header: Text("Sale Information").foregroundColor(.white.opacity(0.7))) {
          HStack {
            Text("Date")
              .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(sale.createdAt.formatted(date: .abbreviated, time: .shortened))
              .foregroundColor(.white)
          }

          HStack {
            Text("Payment Method")
              .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(sale.paymentMethod)
              .foregroundColor(.white)
          }

          if let location = sale.marketLocation {
            HStack {
              Text("Location")
                .foregroundColor(.white.opacity(0.7))
              Spacer()
              Text(location)
                .foregroundColor(.white)
            }
          }
        }
        .listRowBackground(Color.white.opacity(0.15))

        Section(header: Text("Items").foregroundColor(.white.opacity(0.7))) {
          if let items = sale.items {
            ForEach(items) { item in
              HStack {
                Text("\(item.quantity)x \(item.productName)")
                  .foregroundColor(.white)
                Spacer()
                Text(
                  "\(profileVM.selectedCurrency) \(String(format: "%.2f", item.priceAtSale * Double(item.quantity)))"
                )
                .foregroundColor(.white)
              }
            }
          } else {
            Text("No items")
              .foregroundColor(.white.opacity(0.7))
          }
        }
        .listRowBackground(Color.white.opacity(0.15))

        Section(header: Text("Total").foregroundColor(.white.opacity(0.7))) {
          HStack {
            Text("Total Amount")
              .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text("\(profileVM.selectedCurrency) \(String(format: "%.2f", sale.totalAmount))")
              .font(.headline)
              .foregroundColor(.white)
          }
        }
        .listRowBackground(Color.white.opacity(0.15))
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle("Sale Details")
    .navigationBarTitleDisplayMode(.inline)
  }
}
