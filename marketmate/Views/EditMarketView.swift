import SwiftUI

struct EditMarketView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var marketSession: MarketSessionManager

  let market: Market

  @State private var name: String
  @State private var location: String

  init(market: Market) {
    self.market = market
    _name = State(initialValue: market.name)
    _location = State(initialValue: market.location ?? "")
  }

  var body: some View {
    NavigationView {
      ZStack {
        Color.clear.revolutBackground()
          .edgesIgnoringSafeArea(.all)

        Form {
          Section(header: Text("Details").foregroundColor(.marketTextSecondary)) {
            TextField("", text: $name)
              .placeholder(when: name.isEmpty) {
                Text("Market Name").foregroundColor(Color.white.opacity(0.6))
              }
              .foregroundColor(.white)
            
            TextField("", text: $location)
              .placeholder(when: location.isEmpty) {
                Text("Location").foregroundColor(Color.white.opacity(0.6))
              }
              .foregroundColor(.white)
          }
          .listRowBackground(Color.marketCard)
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Edit Market")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveMarket()
          }
          .foregroundColor(.marketGreen)
          .disabled(name.isEmpty)
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.marketTextSecondary)
        }
      }
    }
  }

  private func saveMarket() {
    Task {
      var updatedMarket = market
      updatedMarket.name = name
      updatedMarket.location = location.isEmpty ? nil : location

      await marketSession.updateMarket(updatedMarket)
      dismiss()
    }
  }
}
