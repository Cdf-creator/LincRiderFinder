//
//  MapView.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct EquatableCoordinate: Equatable {
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct MapView: View {
    @EnvironmentObject var locationVM: LocationViewModel
    @State private var userRegion: MKCoordinateRegion?
    @State private var lastSearchedLocation: CLLocation?
    @State private var searchText = "" // State for search input
    @State var selectedPlace: Place? //Store selected place
    @State private var showPlaceDetails = false // Controls detail view visibility
    
    var body: some View {
        VStack(spacing: 10) { // 🔹 Adds spacing between elements
            //Search Bar
            TextField("Search places", text: $searchText)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        // If searchText is empty, show nearby places around the user's location
                        if let userCoordinate = locationVM.userLocation {
                            locationVM.searchForHotels(near: userCoordinate)
                        }
                    } else {
                        // Perform a search using the search text
                        locationVM.searchForPlaces(query: newValue)
                    }
                }
            // Display User Location Details
            VStack(alignment: .leading, spacing: 5) {
                Text("Latitude: \(String(format: "%.3f", locationVM.userLocation?.latitude ?? 0.0))")
                Text("Longitude: \(String(format: "%.3f", locationVM.userLocation?.longitude ?? 0.0))")
                Text("Approx. Address: \(locationVM.userAddress)")
                Text(locationVM.userAltitude)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(radius: 3)
            
            //Map View with Reset Button
            ZStack(alignment: .bottomTrailing) {
                Map(coordinateRegion: Binding(
                    get: { userRegion ?? locationVM.region },
                    set: { userRegion = $0 }
                ), showsUserLocation: true, annotationItems: locationVM.nearbyPlaces) { place in
                    MapAnnotation(coordinate: place.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            Text(place.name)
                                .font(.caption)
                                .bold()
                                .padding(5)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(5)
                        }
                        .contentShape(Rectangle()) //Ensures tappable area
                        .onTapGesture { //Tap to select place
                            DispatchQueue.main.async {
                                selectedPlace = place
                                locationVM.selectedPlace = place
                                if selectedPlace != nil {
                                    showPlaceDetails = true
                                }
                                //showPlaceDetails = true
                                print("here is tapped tapped: place: \(place),  selectedPlace: \(selectedPlace)")
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    if userRegion == nil {
                        userRegion = locationVM.region // Set initial region once
                    }
                }
                .onChange(of: locationVM.userLocation) { newCoordinate in
                    guard let newCoordinate = newCoordinate else { return }
                    let newLocation = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
                    
                    if searchText.isEmpty { // Only update nearby places if searchText is empty
                        if lastSearchedLocation == nil || lastSearchedLocation?.distance(from: newLocation) ?? 0 > 50 {
                            lastSearchedLocation = newLocation
                            locationVM.searchForHotels(near: newCoordinate)
                        }
                    }
                }
                
                //Reset Zoom Button
                Button(action: {
                    withAnimation {
                        userRegion = locationVM.region // Restore original zoom level
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding()
            }
            
            Spacer() //Ensures the map takes up remaining space
        }
        .sheet(isPresented: $showPlaceDetails) {
            if let place = selectedPlace {
                PlaceDetailView(place: place)
            } else {
                if let place = locationVM.selectedPlace {
                    Text(place.name)
                }
            }
        }
    }
}



#Preview {
    MapView()
        .environmentObject(LocationViewModel())
}
