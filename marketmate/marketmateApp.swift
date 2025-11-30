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

  @StateObject private var themeManager = ThemeManager()

  init() {
    AppAppearance.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .environmentObject(themeManager)
        .preferredColorScheme(.light)  // Force light mode
    }
  }
}
