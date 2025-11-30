import SwiftUI

struct MainTabView: View {
  @StateObject private var inventoryVM = InventoryViewModel()
  @StateObject private var salesVM = SalesViewModel()
  @StateObject private var costsVM = CostsViewModel()

  var body: some View {
    TabView {
      NavigationStack {
        HomeView()
          .environmentObject(salesVM)
          .environmentObject(costsVM)
          .environmentObject(inventoryVM)
      }
      .tabItem {
        Label("Home", systemImage: "house.fill")
      }
      .tag(0)

      NavigationStack {
        SalesView()
          .environmentObject(salesVM)
          .environmentObject(inventoryVM)
          .environmentObject(costsVM)
      }
      .tabItem {
        Label("Sales", systemImage: "tag.fill")
      }
      .tag(1)

      NavigationStack {
        InventoryView()
          .environmentObject(inventoryVM)
      }
      .tabItem {
        Label("Inventory", systemImage: "cube.box.fill")
      }
      .tag(2)

      NavigationStack {
        CostsView()
          .environmentObject(costsVM)
      }
      .tabItem {
        Label("Costs", systemImage: "arrow.down.circle.fill")
      }
      .tag(3)
    }
    .tint(.white)
  }
}
