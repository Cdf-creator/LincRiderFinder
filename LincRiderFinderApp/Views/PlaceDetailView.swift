//
//  PlaceDetailView.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import SwiftUI
import MapKit

struct PlaceDetailView: View {
    let place: Place
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @State private var isFavorite = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(place.name)
                .font(.largeTitle)
                .bold()
            
            Text("Address: \(place.address ?? "N/A")")
                .font(.body)
            
            Text("Latitude: \(place.coordinate.latitude)")
            Text("Longitude: \(place.coordinate.longitude)")
            
            Button(action: {
                favoritesVM.toggleFavorite(place: place)
                isFavorite.toggle()
            }) {
                HStack {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                    Text(isFavorite ? "Saved" : "Save to Favorites")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onAppear {
            print("this place is here: \(place.name)")
            if favoritesVM.isFavorite(place: place) {
                isFavorite = true
            } else {
                isFavorite = false
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
}

/*#Preview {
 let samplePlace = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)))
 samplePlace.name = "Golden Gate Bridge"
 
 return PlaceDetailView(place: samplePlace)
 //PlaceDetailView()
 //PlaceDetailView(place: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))))
 }*/
