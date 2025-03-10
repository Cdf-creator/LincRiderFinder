//
//  LocationViewModel.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import Foundation
import MapKit
import CoreLocation


class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var nearbyPlaces: [Place] = []
    @Published var selectedPlace: Place?
    @Published var userAddress: String = "Fetching address..."
    @Published var userAltitude: String = "Fetching altitude..."
    
    private var locationManager = CLLocationManager()
    @Published private var lastSearchedLocation: CLLocation? = nil
    
    private let searchService: LocationSearchService  // Injected dependency
    
     init(searchService: LocationSearchService) {
        self.searchService = searchService
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            print("this is the userLoaction: \(self.userLocation)")
            // self.checkAndSearchForHotels(newLocation: location)
            DispatchQueue.main.async {
                self.fetchAddress(from: location)
                self.fetchAltitude(from: location)
            }
        }
        print("udating searching")
    }
    
    func checkAndSearchForHotels(newLocation: CLLocation) {
        print("checkAndSearchForHotels() is called")
        // If this is the first time searching, set the last searched location
        if lastSearchedLocation == nil {
            lastSearchedLocation = newLocation
            searchForHotels(near: newLocation.coordinate)
            return
        }
        // Calculate distance moved
        let distanceMoved = lastSearchedLocation!.distance(from: newLocation)
        // If user has moved more than 50 meters, trigger a new search
        if distanceMoved > 50 {
            print("only supposed to be called when moved more than 50m")
            lastSearchedLocation = newLocation
            searchForHotels(near: newLocation.coordinate)
        }
    }
    
    func fetchAddress(from location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                self.userAddress = "Address not found"
                return
            }
            self.userAddress = [
                placemark.name,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")
        }
    }
    
    func fetchAltitude(from location: CLLocation) {
        self.userAltitude = "Altitude: \(String(format: "%.3f", location.altitude)) meters"
    }
    
    //Without Using the LocalSearchService Dependency Injection
   /* func searchForHotels(near coordinate: CLLocationCoordinate2D) {
        print("searching is searching")
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Hotel"
        request.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            
            DispatchQueue.main.async {
                self.nearbyPlaces = response.mapItems.map { Place(mapItem: $0) }
                print("this is the nearbyPlaces: \(self.nearbyPlaces)")
            }
        }
    }*/
    
    //Using the LocalSearchService Dependency Injection
    func searchForHotels(near coordinate: CLLocationCoordinate2D) {
            let searchRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )

            searchService.search(query: "Hotel", region: searchRegion) { places in
                DispatchQueue.main.async {
                    self.nearbyPlaces = places
                }
            }
        }
    
    //Without Using the LocalSearchService Dependency Injection
   /* func searchForPlaces(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: userLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            
            DispatchQueue.main.async {
                self.nearbyPlaces = response.mapItems.map { Place(mapItem: $0) }
            }
        }
    }*/
    
    //Using the LocalSearchService Dependency Injection
    func searchForPlaces(query: String) {
            let searchRegion = MKCoordinateRegion(
                center: userLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )

            searchService.search(query: query, region: searchRegion) { places in
                DispatchQueue.main.async {
                    self.nearbyPlaces = places
                }
            }
        }
    
}
