//
//  LincRiderFinderAppApp.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import SwiftUI

@main
struct LincRiderFinderAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(FavoritesViewModel(context: persistenceController.container.viewContext))
        }
    }
}
                    
