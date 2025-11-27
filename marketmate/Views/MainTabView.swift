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
    .onAppear {
      // Force appearance configuration when view appears
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()

      // Dark background - Almost black blue
      appearance.backgroundColor = UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.95)

      // Item appearance
      let itemAppearance = UITabBarItemAppearance()

      // Normal (Unselected) - White
      itemAppearance.normal.iconColor = UIColor.white
      itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]

      // Selected - White
      itemAppearance.selected.iconColor = UIColor.white
      itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

      appearance.stackedLayoutAppearance = itemAppearance
      appearance.inlineLayoutAppearance = itemAppearance
      appearance.compactInlineLayoutAppearance = itemAppearance

      UITabBar.appearance().standardAppearance = appearance
      UITabBar.appearance().scrollEdgeAppearance = appearance

      // Fallbacks
      UITabBar.appearance().barTintColor = UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.95)
      UITabBar.appearance().unselectedItemTintColor = UIColor.white
      UITabBar.appearance().tintColor = UIColor.white
    }
  }
}
