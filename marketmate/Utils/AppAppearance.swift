import SwiftUI

enum AppAppearance {
  static func configure() {
    configureNavigationBar()
    configureTabBar()
  }

  private static func configureNavigationBar() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
  }

  private static func configureTabBar() {
    let tabAppearance = UITabBarAppearance()
    tabAppearance.configureWithOpaqueBackground()
    tabAppearance.backgroundColor = UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.95)

    let itemAppearance = UITabBarItemAppearance()
    itemAppearance.normal.iconColor = UIColor.white
    itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
    itemAppearance.selected.iconColor = UIColor.white
    itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

    tabAppearance.stackedLayoutAppearance = itemAppearance
    tabAppearance.inlineLayoutAppearance = itemAppearance
    tabAppearance.compactInlineLayoutAppearance = itemAppearance

    UITabBar.appearance().standardAppearance = tabAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    UITabBar.appearance().barTintColor = tabAppearance.backgroundColor
    UITabBar.appearance().tintColor = .white
    UITabBar.appearance().unselectedItemTintColor = .white
  }
}
