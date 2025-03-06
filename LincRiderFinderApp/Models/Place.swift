//
//  Place.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import Foundation
import CoreLocation
import MapKit

struct Place: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String? //Add address property
    let category: String? //Added category property

    init(mapItem: MKMapItem) {
        self.name = mapItem.name ?? "Unknown"
        self.coordinate = mapItem.placemark.coordinate
        self.address = mapItem.placemark.title //Extract address
        self.category = mapItem.pointOfInterestCategory?.rawValue //Extract category
    }

    //Implement Equatable
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.id == rhs.id
    }
}

