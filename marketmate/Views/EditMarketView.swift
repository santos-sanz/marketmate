import SwiftUI

struct EditMarketView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var marketSession: MarketSessionManager
  @EnvironmentObject var themeManager: ThemeManager

  let market: Market

  @State private var name: String
  @State private var location: String

  private var textColor: Color { themeManager.primaryTextColor }
  private var secondaryTextColor: Color { themeManager.secondaryTextColor }
  private var cardBackground: Color { themeManager.cardBackground }

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
          Section(header: Text("Details").foregroundColor(secondaryTextColor)) {
            TextField("", text: $name)
              .placeholder(when: name.isEmpty) {
                Text("Market Name").foregroundColor(secondaryTextColor)
              }
              .foregroundColor(textColor)
            
            TextField("", text: $location)
              .placeholder(when: location.isEmpty) {
                Text("Location").foregroundColor(secondaryTextColor)
              }
              .foregroundColor(textColor)
          }
          .listRowBackground(cardBackground)
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Edit Market")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveMarket()
          }
          .foregroundColor(textColor)
          .disabled(name.isEmpty)
        }

        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(secondaryTextColor)
      }
    }
    .themedNavigationBars(themeManager)
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
