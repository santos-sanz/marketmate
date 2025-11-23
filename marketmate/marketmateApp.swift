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

    // Configure TabBar with glassmorphism effect
    let tabAppearance = UITabBarAppearance()
    tabAppearance.configureWithTransparentBackground()
    tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
    tabAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.95)  // More opaque

    // Icon colors - higher contrast
    tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.marketBlue)
    tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray

    // Text colors - higher contrast
    tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
      .foregroundColor: UIColor(Color.marketBlue)
    ]
    tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
      .foregroundColor: UIColor.lightGray
    ]

    UITabBar.appearance().standardAppearance = tabAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabAppearance

    // Enhanced shadow for better separation
    UITabBar.appearance().layer.shadowColor = UIColor.black.cgColor
    UITabBar.appearance().layer.shadowOffset = CGSize(width: 0, height: -3)
    UITabBar.appearance().layer.shadowRadius = 10
    UITabBar.appearance().layer.shadowOpacity = 0.15
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .preferredColorScheme(.light)  // Force light mode
    }
  }
}
