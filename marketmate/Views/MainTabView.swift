import SwiftUI

struct MainTabView: View {
  @StateObject private var inventoryVM = InventoryViewModel()
  @StateObject private var salesVM = SalesViewModel()
  @StateObject private var costsVM = CostsViewModel()

  var body: some View {
    TabView {
      HomeView()
        .environmentObject(salesVM)
        .environmentObject(costsVM)
        .environmentObject(inventoryVM)  // Pass inventoryVM if needed by HomeView subviews
        .tabItem {
          Label("Home", systemImage: "house.fill")
        }
        .tag(0)

      SalesView()
        .environmentObject(salesVM)
        .environmentObject(inventoryVM)
        .tabItem {
          Label("Sales", systemImage: "tag.fill")
        }
        .tag(1)

      InventoryView()
        .environmentObject(inventoryVM)
        .tabItem {
          Label("Inventory", systemImage: "cube.box.fill")
        }
        .tag(2)

      CostsView()
        .environmentObject(costsVM)
        .tabItem {
          Label("Costs", systemImage: "arrow.down.circle.fill")
        }
        .tag(3)
    }
    .accentColor(.marketBlue)
  }
}
