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
    tabAppearance.configureWithTransparentBackground()
    
    // Darker background for better contrast with white icons
    tabAppearance.backgroundColor = UIColor(white: 0.0, alpha: 0.3)  // Dark semi-transparent background
    
    // Icon colors - Pure White for both selected and unselected
    tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
    tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
    
    // Text colors - White
    tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
      .foregroundColor: UIColor.white
    ]
    tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
      .foregroundColor: UIColor.white.withAlphaComponent(0.7)
    ]

    UITabBar.appearance().standardAppearance = tabAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    
    // Explicitly set tint color to white to prevent any system overrides
    UITabBar.appearance().tintColor = UIColor.white
    UITabBar.appearance().unselectedItemTintColor = UIColor.white

    // Remove shadow to keep it clean
    UITabBar.appearance().layer.shadowColor = UIColor.clear.cgColor
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .preferredColorScheme(.light)  // Force light mode
    }
  }
}
