//
//  MKLocalSearchService.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 10/03/2025.
//

import Foundation
import MapKit

class MKLocalSearchService: LocationSearchService {
    func search(query: String, region: MKCoordinateRegion, completion: @escaping ([Place]) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                completion([]) // Return empty array on failure
                return
            }

            let places = response.mapItems.map { Place(mapItem: $0) }
            completion(places)
        }
    }
}
