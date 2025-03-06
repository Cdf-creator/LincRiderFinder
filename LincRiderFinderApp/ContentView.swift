//
//  ContentView.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var locationVM = LocationViewModel()
    @StateObject var favoritesVM = FavoritesViewModel(context: PersistenceController.shared.container.viewContext)

    var body: some View {
        NavigationView {
                    VStack {
                        NavigationLink(destination: MapView()) {
                            Text("View Map")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        /*NavigationLink(destination: FavoritesView()) {
                            Text("View Favorites")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }*/
                        NavigationLink(destination: FavoritesView()
                                                        .environmentObject(locationVM)) {
                                            Text("View Favorites")
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                    }
                    .navigationTitle("LINCRIDE Finder")
                    .environmentObject(favoritesVM)
                }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
