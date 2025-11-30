import SwiftUI

struct MainTabView: View {
  @StateObject private var inventoryVM = InventoryViewModel()
  @StateObject private var salesVM = SalesViewModel()
  @StateObject private var costsVM = CostsViewModel()
  @EnvironmentObject var profileVM: ProfileViewModel
  @EnvironmentObject var themeManager: ThemeManager
  @State private var selectedTab = 0

  var body: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: $selectedTab) {
        NavigationStack {
          HomeView()
            .environmentObject(salesVM)
            .environmentObject(costsVM)
            .environmentObject(inventoryVM)
        }
        .themedNavigationBars(themeManager)
        .tag(0)

        NavigationStack {
          SalesView()
            .environmentObject(salesVM)
            .environmentObject(inventoryVM)
            .environmentObject(costsVM)
        }
        .themedNavigationBars(themeManager)
        .tag(1)

        if profileVM.useInventory {
          NavigationStack {
            InventoryView()
              .environmentObject(inventoryVM)
          }
          .themedNavigationBars(themeManager)
          .tag(2)
        }

        NavigationStack {
          CostsView()
            .environmentObject(costsVM)
        }
        .themedNavigationBars(themeManager)
        .tag(3)
      }
      .tint(themeManager.tabTint)

      CustomTabBar(selectedTab: $selectedTab)
        .padding(.bottom, 0)
    }
    .ignoresSafeArea(.keyboard)
    .onAppear {
      UITabBar.appearance().isHidden = true
    }
    .onChange(of: profileVM.useInventory) { newValue in
      if !newValue, selectedTab == 2 {
        selectedTab = 0
      }
    }
  }
}
