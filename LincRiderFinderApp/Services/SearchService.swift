//
//  SearchService.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import MapKit
import Combine

class SearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchResults: [String] = []
    private var searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        searchCompleter.delegate = self
    }

    func updateSearchQuery(_ query: String) {
        searchCompleter.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results.map { $0.title }
    }
}

