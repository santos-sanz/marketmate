//
//  marketmateApp.swift
//  marketmate
//
//  Created by Andrés Santos Sanz on 2025-11-22.
//

import CoreData
import SwiftUI

@main
struct marketmateApp: App {
  let persistenceController = PersistenceController.shared

  init() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance

    // Configure TabBar with darker background and white icons
    let tabAppearance = UITabBarAppearance()
    tabAppearance.configureWithOpaqueBackground()

    // Darker background for better contrast with white icons - Almost black blue
    tabAppearance.backgroundColor = UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.95)

    // Create item appearance configuration
    let itemAppearance = UITabBarItemAppearance()

    // Unselected state - White
    itemAppearance.normal.iconColor = UIColor.white
    itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]

    // Selected state - White
    itemAppearance.selected.iconColor = UIColor.white
    itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]

    // Apply item appearance to all layouts
    tabAppearance.stackedLayoutAppearance = itemAppearance
    tabAppearance.inlineLayoutAppearance = itemAppearance
    tabAppearance.compactInlineLayoutAppearance = itemAppearance

    UITabBar.appearance().standardAppearance = tabAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabAppearance

    // Fallback for older iOS versions or unhandled cases
    UITabBar.appearance().barTintColor = UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.95)
    UITabBar.appearance().tintColor = UIColor.white
    UITabBar.appearance().unselectedItemTintColor = UIColor.white

    // Remove shadow to keep it clean
    UITabBar.appearance().layer.shadowColor = UIColor.clear.cgColor
    UITabBar.appearance().unselectedItemTintColor = UIColor.white
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .preferredColorScheme(.light)  // Force light mode
    }
  }
}
