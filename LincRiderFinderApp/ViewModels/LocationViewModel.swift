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
    @Published var userAddress: String = "Fetching address..."
    @Published var userAltitude: String = "Fetching altitude..."
    @Published var nearbyPlaces: [Place] = []
    @Published var isPerformingSearch = false  //Track if user is searching
    @Published var region: MKCoordinateRegion  = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
    )
    
    private let locationManager = CLLocationManager()
    @Published var hasUpdatedRegion = false  //Prevents unnecessary auto-zooming
    
    @Published var selectedPlace: Place?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        //Prevent unnecessary updates if movement is small
        if let lastLocation = userLocation {
            let last = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
            let current = CLLocation(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
            
            let distance = last.distance(from: current) //Get distance in meters
            
            if distance < 50 { return } //Ignore minor movements
        }
        
        DispatchQueue.main.async {
            self.userLocation = newLocation.coordinate //Update only if moved significantly
            self.fetchNearbyPlaces()
            self.fetchAddress(from: newLocation)
            self.fetchAltitude(from: newLocation)
        }
    }
    
    /*  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     guard let location = locations.last else { return }
     userLocation = location.coordinate
     fetchNearbyPlaces()
     fetchAddress(from: location)
     fetchAltitude(from: location)
     }*/
    
    
    func distanceBetween(_ coord1: CLLocationCoordinate2D?, _ coord2: CLLocationCoordinate2D?) -> CLLocationDistance {
        guard let coord1 = coord1, let coord2 = coord2 else { return 0 }
        
        let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        
        return loc1.distance(from: loc2) //Returns distance in meters
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func fetchNearbyPlaces() {
        guard let userLocation = locationManager.location?.coordinate else { return }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "Hotel"
        
        //Use a smaller search radius (~3-5 meters)
        searchRequest.region = MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.0003, longitudeDelta: 0.0003)
        )
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else { return }
            
            let minDistance: CLLocationDistance = 10 //Ensure at least 10m distance from user
            
            let filteredResults = response.mapItems
                .filter { $0.placemark.location?.distance(from: CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)) ?? 0 > minDistance }
                .prefix(5) //Limit to 5 results to avoid clutter
            
            self.nearbyPlaces = filteredResults.map { Place(mapItem: $0) }
        }
    }
    
    
    private func fetchAddress(from location: CLLocation) {
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
    
    private func fetchAltitude(from location: CLLocation) {
        self.userAltitude = "Altitude: \(location.altitude) meters"
    }
    
    // Keeps places visible dynamically
    func updateRegionForPlaces() {
        guard !self.nearbyPlaces.isEmpty else { return }
        
        if isPerformingSearch { return } //Prevent override during search
        
        let allCoordinates = self.nearbyPlaces.map { $0.coordinate }
        let userCoordinate = self.userLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let allPoints = [userCoordinate] + allCoordinates
        
        var minLat = allPoints.map { $0.latitude }.min() ?? userCoordinate.latitude
        var maxLat = allPoints.map { $0.latitude }.max() ?? userCoordinate.latitude
        var minLon = allPoints.map { $0.longitude }.min() ?? userCoordinate.longitude
        var maxLon = allPoints.map { $0.longitude }.max() ?? userCoordinate.longitude
        
        let padding = 0.005  //Adjusts spacing for better view
        minLat -= padding
        maxLat += padding
        minLon -= padding
        maxLon += padding
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon
        
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
    
    
    func searchForPlaces(query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.nearbyPlaces = []
                self.fetchNearbyPlaces() //Reload nearby places
                self.updateRegionForPlaces() //Reset the map to user location & nearby places/
                self.isPerformingSearch = false
            }
            return
        }
        
        isPerformingSearch = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region // Use current region for search accuracy
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let items = response?.mapItems, error == nil else {
                self.isPerformingSearch = false
                return
            }
            
            DispatchQueue.main.async {
                self.nearbyPlaces = items.map { Place(mapItem: $0) }
                self.updateRegionForSearchResults()
                self.isPerformingSearch = false
            }
        }
    }
    
    private func updateRegionForSearchResults() {
        guard !nearbyPlaces.isEmpty else { return }
        
        let coordinates = nearbyPlaces.map { $0.coordinate }
        
        var minLat = coordinates.map { $0.latitude }.min() ?? region.center.latitude
        var maxLat = coordinates.map { $0.latitude }.max() ?? region.center.latitude
        var minLon = coordinates.map { $0.longitude }.min() ?? region.center.longitude
        var maxLon = coordinates.map { $0.longitude }.max() ?? region.center.longitude
        
        let padding = 0.005
        minLat -= padding
        maxLat += padding
        minLon -= padding
        maxLon += padding
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon
        
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
}
