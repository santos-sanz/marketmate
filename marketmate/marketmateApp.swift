//
//  marketmateApp.swift
//  marketmate
//
//  Created by Andrés Santos Sanz on 2025-11-22.
//

import SwiftUI
import CoreData

@main
struct marketmateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
