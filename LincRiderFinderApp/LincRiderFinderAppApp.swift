//
//  LincRiderFinderAppApp.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import SwiftUI

@main
struct LincRiderFinderAppApp: App {
    @StateObject var locationVM = LocationViewModel()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(locationVM) 
                .environmentObject(FavoritesViewModel(context: persistenceController.container.viewContext))
        }
    }
}
