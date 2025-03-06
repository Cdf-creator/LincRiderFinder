//
//  FavoritesView.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 05/03/2025.
//

import SwiftUI
import MapKit
import CoreData
import CoreLocation

struct FavoritesView: View {
    @FetchRequest(
        entity: FavoritePlace.entity(),
        sortDescriptors: []
    ) var favoritePlaces: FetchedResults<FavoritePlace>

    @EnvironmentObject var locationVM: LocationViewModel // Access shared LocationViewModel

    var body: some View {
        VStack {
            if favoritePlaces.isEmpty {
                Text("You haven't added any favorites yet. Add places to view them.")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Center text on the screen
                    .multilineTextAlignment(.center) // Optional, for better multi-line text alignment
            } else {
                List {
                    ForEach(favoritePlaces, id: \.id) { place in
                        NavigationLink(
                            destination: MapView().onAppear {
                                locationVM.region = MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            }
                        ) {
                            Text(place.name ?? "Unknown Place")
                        }
                    }
                    .onDelete(perform: deletePlace)
                }
            }
        }
        .navigationTitle("Saved Places")
    }

    private func deletePlace(at offsets: IndexSet) {
        let context = PersistenceController.shared.container.viewContext
        offsets.map { favoritePlaces[$0] }.forEach(context.delete)

        do {
            try context.save()
        } catch {
            print("Failed to delete: \(error)")
        }
    }
}

#Preview {
    FavoritesView()
}
