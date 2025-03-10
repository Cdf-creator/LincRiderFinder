//
//  LincRiderFinderAppTests.swift
//  LincRiderFinderAppTests
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import XCTest
import CoreData
import MapKit
@testable import LincRiderFinderApp

class ViewModelTests: XCTestCase {
    
    // MARK: - Properties
    var locationViewModel: LocationViewModel!
    var favoritesViewModel: FavoritesViewModel!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        let container = NSPersistentContainer(name: "LincRiderFinderApp") // Replace with your Core Data model name
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        let expectation = XCTestExpectation(description: "Load Core Data Persistent Stores")
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load in-memory store: \(error?.localizedDescription ?? "")")
            self.testContext = container.viewContext
            self.favoritesViewModel = FavoritesViewModel(context: self.testContext)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0) // Wait for Core Data to be ready
        
        // Initialize
        //LocationViewModel = LocationViewModel()
        locationViewModel = LocationViewModel(searchService: MockLocationSearchService())
    }
    
    override func tearDown() {
        favoritesViewModel = nil
        testContext = nil
        locationViewModel = nil
        super.tearDown()
    }
    
    // MARK: - LocationViewModel Tests
    func testLocationUpdates() {
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let expectation = XCTestExpectation(description: "Wait for location update")
        
        // Observe when userLocation changes
        let cancellable = locationViewModel.$userLocation.sink { location in
            if let location = location {
                XCTAssertEqual(location.latitude, mockLocation.coordinate.latitude)
                XCTAssertEqual(location.longitude, mockLocation.coordinate.longitude)
                expectation.fulfill() // Mark the expectation as fulfilled
            }
        }
        
        // Simulate location update
        locationViewModel.locationManager(CLLocationManager(), didUpdateLocations: [mockLocation])
        
        // Wait up to 2 seconds for the async update to complete
        wait(for: [expectation], timeout: 2.0)
        
        // Cleanup
        cancellable.cancel()
    }
    
    func testFetchAddress() {
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let expectation = XCTestExpectation(description: "Fetching address")
        
        locationViewModel.fetchAddress(from: mockLocation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            XCTAssertNotEqual(self.locationViewModel.userAddress, "Fetching address...")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFetchAltitude() {
        let mockLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 50.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        locationViewModel.fetchAltitude(from: mockLocation)
        
        XCTAssertEqual(locationViewModel.userAltitude, "Altitude: 50.000 meters")
    }
    
    func testCheckAndSearchForHotels() {
        let mockLocation1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let mockLocation2 = CLLocation(latitude: 37.7759, longitude: -122.4194) // ~111 meters away
        
        locationViewModel.checkAndSearchForHotels(newLocation: mockLocation1)
        XCTAssertNotNil(locationViewModel.nearbyPlaces)
        
        locationViewModel.checkAndSearchForHotels(newLocation: mockLocation2)
        XCTAssertNotNil(locationViewModel.nearbyPlaces)
    }
    
    
    // MARK: - FavoritesViewModel Tests
    func testFavoritesFunctionality() {
        let place1 = Place(
            mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)))
        )
        
        let place2 = Place(
            mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.1, longitude: -122.1)))
        )
        
        // Test initially empty favorites
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 0)
        XCTAssertFalse(favoritesViewModel.isFavorite(place: place1))
        
        // Test saving a place
        favoritesViewModel.saveToFavorites(place: place1)
        XCTAssertTrue(favoritesViewModel.isFavorite(place: place1))
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 1)
        
        // Test removing a place
        favoritesViewModel.removeFromFavorites(place: place1)
        XCTAssertFalse(favoritesViewModel.isFavorite(place: place1))
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 0)
        
        // Test toggling favorites
        favoritesViewModel.toggleFavorite(place: place1)
        XCTAssertTrue(favoritesViewModel.isFavorite(place: place1))
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 1)
        
        favoritesViewModel.toggleFavorite(place: place1)
        XCTAssertFalse(favoritesViewModel.isFavorite(place: place1))
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 0)
        
        // Test fetching multiple places
        favoritesViewModel.saveToFavorites(place: place1)
        favoritesViewModel.saveToFavorites(place: place2)
        favoritesViewModel.fetchFavorites()
        
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 2)
    }
    
    
    // MARK: - Combined Tests for Location and Favorites ViewModels
    
    // Test that a place fetched from the LocationViewModel can be added to favorites
    func testFetchAndAddPlaceToFavorites() throws {
        // Create a coordinate
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Create an address dictionary (Optional, but helpful for thoroughfare)
        let addressDict: [String: Any] = [
            "Street": "123 Test St"
        ]
        
        // Create an MKPlacemark with a coordinate and address dictionary
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        
        // Create an MKMapItem from the placemark
        let mockMapItem = MKMapItem(placemark: placemark)
        mockMapItem.name = "Test Hotel" // Assign a name directly
        
        // Create a Place object from MKMapItem
        let mockPlace = Place(mapItem: mockMapItem)
        
        // Simulate fetching places in LocationViewModel
        locationViewModel.nearbyPlaces = [mockPlace]
        
        // Add the fetched place to favorites
        favoritesViewModel.toggleFavorite(place: mockPlace)
        
        // Ensure that the place is now in favorites
        XCTAssertTrue(favoritesViewModel.isFavorite(place: mockPlace), "The fetched place should be added to favorites.")
    }
    
}
