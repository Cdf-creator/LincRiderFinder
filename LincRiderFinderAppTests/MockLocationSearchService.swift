//
//  MockLocationSearchService.swift
//  LincRiderFinderAppTests
//
//  Created by Olanrewaju Olakunle  on 06/03/2025.
//

import MapKit
@testable import LincRiderFinderApp

/*class MockLocationSearchService: LocationSearchService {
    func search(query: String, region: MKCoordinateRegion, completion: @escaping ([Place]) -> Void) {
        let mockPlaces = [
            Place(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))))
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Simulate async delay
            completion(mockPlaces)
        }
    }
}*/

import MapKit
@testable import LincRiderFinderApp

class MockLocationSearchService: LocationSearchService {
    func search(query: String, region: MKCoordinateRegion, completion: @escaping ([Place]) -> Void) {
        let mockPlaces = [
            Place(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))))
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(mockPlaces)
        }
    }
}
