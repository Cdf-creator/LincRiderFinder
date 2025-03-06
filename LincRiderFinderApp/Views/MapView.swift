//
//  MapView.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import SwiftUI
import MapKit

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

import CoreLocation

struct EquatableCoordinate: Equatable {
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject var locationVM = LocationViewModel()
    @State private var hasUpdatedRegion = false  //Prevents unnecessary auto-zooming
    
    @State private var cameraPosition: MapCameraPosition = .automatic //Use MapCameraPosition for iOS 17+
    
    @State var selectedPlace: Place? //Store selected place
    @State private var showPlaceDetails = false // Controls detail view visibility
    @State private var searchText = "" //Store search input
    @EnvironmentObject var favoritesVM: FavoritesViewModel  // Access the injected favoritesVM here
    
    var body: some View {
        VStack {
            //Search Bar
            TextField("Search places", text: $searchText)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
                .onChange(of: searchText) { _, newValue in
                    locationVM.searchForPlaces(query: newValue) // Trigger search
                }
            
            //Display User Location Details
            VStack(alignment: .leading) {
                Text("Latitude: \(locationVM.userLocation?.latitude ?? 0.0)")
                Text("Longitude: \(locationVM.userLocation?.longitude ?? 0.0)")
                Text("Approx. Address: \(locationVM.userAddress)")
                Text(locationVM.userAltitude)
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .padding(.horizontal)
            //Map Display
            Map(coordinateRegion: $locationVM.region, showsUserLocation: true, annotationItems: locationVM.nearbyPlaces) { place in
                MapAnnotation(coordinate: place.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                        
                        Text(place.name)
                            .font(.caption)
                            .bold()
                            .background(Color.white)
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
            // .edgesIgnoringSafeArea(.all)
            .onChange(of: locationVM.userLocation) { oldLocation, newLocation in
                if let newLocation = newLocation {
                    if !hasUpdatedRegion || oldLocation == nil || locationVM.distanceBetween(oldLocation, newLocation) > 50 { //Update only if moved significantly
                        withAnimation {
                            locationVM.region = MKCoordinateRegion(
                                center: newLocation,
                                span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001) //More reasonable zoom level
                            )
                        }
                        hasUpdatedRegion = true
                    }
                }
            }
            .onChange(of: locationVM.nearbyPlaces) {
                locationVM.updateRegionForPlaces()
            }
            .onAppear{
                print(locationVM.nearbyPlaces)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showPlaceDetails) {
            if let place = selectedPlace {
                PlaceDetailView(place: place)
                    .environmentObject(favoritesVM)  // Pass favoritesVM here
            } else {
                if let place = locationVM.selectedPlace {
                    Text(place.name)
                }
            }
        }
        .onAppear {
            locationVM.requestLocation()
        }
    }
    
}

#Preview {
    MapView()
}
