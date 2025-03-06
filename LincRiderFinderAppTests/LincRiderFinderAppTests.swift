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
    var mockContext: NSManagedObjectContext!
    
    // MARK: - Setup and Teardown
    override func setUpWithError() throws {
        let container = NSPersistentContainer(name: "LincRiderFinderApp") //Actual model name
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        let expectation = XCTestExpectation(description: "Load Core Data Stack")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load Core Data stack: \(error)")
                return
            }
            self.mockContext = container.viewContext
            self.favoritesViewModel = FavoritesViewModel(context: self.mockContext)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        locationViewModel = LocationViewModel()
    }
    
    override func tearDownWithError() throws {
        locationViewModel = nil
        favoritesViewModel = nil
        mockContext = nil
    }
    
    // MARK: - LocationViewModel Tests
    
    // Test location updates
    func testLocationUpdate() throws {
        // Arrange
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let expectation = XCTestExpectation(description: "Location should be updated")
        
        // Reset userLocation
        locationViewModel.userLocation = nil
        
        // Act - Manually update userLocation without relying on CLLocationManager
        DispatchQueue.main.async {
            self.locationViewModel.userLocation = mockLocation.coordinate
            expectation.fulfill()
        }
        
        // Wait for async update
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(locationViewModel.userLocation?.latitude, 37.7749, "Latitude should match.")
        XCTAssertEqual(locationViewModel.userLocation?.longitude, -122.4194, "Longitude should match.")
    }
    
    // Test for fetching nearby places
    func testFetchNearbyPlaces() throws {
        // Arrange
        let mockPlace = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)))
        mockPlace.name = "Test Hotel"
        
        // Create a mock MKLocalSearchRequest and MKLocalSearch instance
        let searchRequest = MKLocalSearch.Request()
        let mockSearch = MKLocalSearch(request: searchRequest)
        
        // Mocking the MKLocalSearch behavior using the completionHandler
        mockSearch.start { response, error in
            if let response = response {
                // Simulate adding the mockPlace to the view model
                self.locationViewModel.nearbyPlaces = response.mapItems.map { mapItem in
                    Place(mapItem: mapItem)
                }
            }
        }
        
        // Act
        locationViewModel.fetchNearbyPlaces()  // Call the method being tested
        
        // Assert that the fetched places are not empty
        XCTAssertFalse(locationViewModel.nearbyPlaces.isEmpty, "Nearby places should not be empty.")
    }
    
    // Test searchForPlaces method
    func testSearchForPlaces() throws {
        // Arrange
        let mockSearchResults = [Place(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))))]
        
        locationViewModel.isPerformingSearch = true
        
        // Mock the search response
        locationViewModel.searchForPlaces(query: "Hotel")
        
        // Act
        locationViewModel.searchForPlaces(query: "Hotel")
        
        // Assert
        XCTAssertTrue(locationViewModel.isPerformingSearch, "Search should be performing.")
        XCTAssertFalse(locationViewModel.nearbyPlaces.isEmpty, "Nearby places should not be empty after search.")
    }
    
    // Test the distanceBetween function
    func testDistanceBetween() {
        // Arrange
        let coord1 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let coord2 = CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712)
        
        // Act
        let distance = locationViewModel.distanceBetween(coord1, coord2)
        
        // Assert
        XCTAssertGreaterThan(distance, 0, "Distance should be greater than 0.")
    }
    
    // Test region update for places
    func testUpdateRegionForPlaces() {
        // Arrange
        locationViewModel.userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        locationViewModel.nearbyPlaces = [
            Place(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)))),
            Place(mapItem: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712))))
        ]
        
        // Act
        locationViewModel.updateRegionForPlaces()
        
        // Assert
        XCTAssertNotNil(locationViewModel.region.center, "Region center should be updated.")
        XCTAssertGreaterThan(locationViewModel.region.span.latitudeDelta, 0, "Region span should have a non-zero latitude delta.")
    }
    
    // MARK: - FavoritesViewModel Tests
    // Test fetch favorites
    func testFetchFavorites() throws {
        // Create an MKPlacemark with the required coordinate
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        
        // Create an MKMapItem with the placemark
        let mockMapItem = MKMapItem(placemark: placemark)
        mockMapItem.name = "Test Hotel"
        // Mocking address here by assigning it directly to the title
        placemark.setValue("123 Test St", forKey: "title")  // This workaround allows us to mock the title
        
        // Create the Place from the MKMapItem
        let mockPlace = Place(mapItem: mockMapItem)
        
        // Add the place to favorites
        favoritesViewModel.toggleFavorite(place: mockPlace)
        
        // Fetch favorites and verify
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 1, "Favorite places should contain one item.")
        XCTAssertEqual(favoritesViewModel.favoritePlaces.first?.name, mockPlace.name, "The fetched favorite place's name should match.")
    }
    
    // Test if the place is favorite
    func testIsFavorite() throws {
        // Create a mock MKPlacemark with required coordinates
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        
        // Create an MKMapItem with the placemark
        let mockMapItem = MKMapItem(placemark: placemark)
        mockMapItem.name = "Test Hotel"
        placemark.setValue("123 Test St", forKey: "title")  // Workaround to mock the address
        
        // Create the Place object from the MKMapItem
        let mockPlace = Place(mapItem: mockMapItem)
        
        // Ensure the place is not a favorite initially
        XCTAssertFalse(favoritesViewModel.isFavorite(place: mockPlace), "The place should not be in favorites.")
        
        // Add the place to favorites
        favoritesViewModel.toggleFavorite(place: mockPlace)
        
        // Ensure the place is now a favorite
        XCTAssertTrue(favoritesViewModel.isFavorite(place: mockPlace), "The place should be in favorites.")
    }
    
    // Test toggle favorite (add and remove)
    func testToggleFavorite() throws {
        // Create a mock MKPlacemark with required coordinates
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        
        // Create an MKMapItem with the placemark
        let mockMapItem = MKMapItem(placemark: placemark)
        mockMapItem.name = "Test Hotel"
        placemark.setValue("123 Test St", forKey: "title")  // Workaround to mock the address
        
        // Create the Place object from the MKMapItem
        let mockPlace = Place(mapItem: mockMapItem)
        
        // Ensure the place is not a favorite initially
        XCTAssertFalse(favoritesViewModel.isFavorite(place: mockPlace), "The place should not be in favorites.")
        
        // Add the place to favorites
        favoritesViewModel.toggleFavorite(place: mockPlace)
        
        // Ensure the place is now in favorites
        XCTAssertTrue(favoritesViewModel.isFavorite(place: mockPlace), "The place should be added to favorites.")
        
        // Remove the place from favorites
        favoritesViewModel.toggleFavorite(place: mockPlace)
        
        // Ensure the place is removed from favorites
        XCTAssertFalse(favoritesViewModel.isFavorite(place: mockPlace), "The place should be removed from favorites.")
    }
    
    // Test saving and removing from favorites
    func testSaveAndRemoveFavorite() throws {
        // Create a mock MKPlacemark with the required coordinate
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        
        // Create an MKMapItem with the placemark
        let mockMapItem = MKMapItem(placemark: placemark)
        mockMapItem.name = "Test Hotel"
        
        // Mock the address using setValue (workaround for the immutable title)
        placemark.setValue("123 Test St", forKey: "title")
        
        // Create the Place object from the MKMapItem
        let mockPlace = Place(mapItem: mockMapItem)
        
        // Save to favorites
        favoritesViewModel.saveToFavorites(place: mockPlace)
        
        // Check if it was saved
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 1, "The favorite places should contain one item.")
        XCTAssertEqual(favoritesViewModel.favoritePlaces.first?.name, mockPlace.name, "The favorite place should have the same name.")
        
        // Remove from favorites
        favoritesViewModel.removeFromFavorites(place: mockPlace)
        
        // Verify it's removed
        XCTAssertEqual(favoritesViewModel.favoritePlaces.count, 0, "The favorite places should be empty.")
    }
    
    
    // MARK: - Combined Tests for Location and Favorites ViewModels
    
    // Test that a place fetched from the LocationViewModel can be added to favorites
    func testFetchAndAddPlaceToFavorites() throws {
        // Create a mock MKPlacemark with the required coordinate
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        
        // Create an MKMapItem with the placemark
        let mockMapItem = MKMapItem(placemark: placemark)
        mockMapItem.name = "Test Hotel"
        
        // Mock the address using setValue (workaround for the immutable title)
        placemark.setValue("123 Test St", forKey: "title")
        
        // Create the Place object from the MKMapItem
        let mockPlace = Place(mapItem: mockMapItem)
        
        // Simulate fetching places in the LocationViewModel
        locationViewModel.nearbyPlaces = [mockPlace]
        
        // Add the fetched place to favorites
        favoritesViewModel.toggleFavorite(place: mockPlace)
        
        // Ensure that the place is now in favorites
        XCTAssertTrue(favoritesViewModel.isFavorite(place: mockPlace), "The fetched place should be added to favorites.")
    }
    
}
