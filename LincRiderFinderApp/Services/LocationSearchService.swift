//
//  LocationSearchService.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 10/03/2025.
//

import Foundation
import MapKit

protocol LocationSearchService {
    func search(query: String, region: MKCoordinateRegion, completion: @escaping ([Place]) -> Void)
}
