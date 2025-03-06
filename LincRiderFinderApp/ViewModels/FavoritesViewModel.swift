//
//  FavoritesViewModel.swift
//  LincRiderFinderApp
//
//  Created by Olanrewaju Olakunle  on 04/03/2025.
//

import Foundation
import CoreData
import SwiftUI

class FavoritesViewModel: ObservableObject {
    @Published var favoritePlaces: [FavoritePlace] = []
    
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchFavorites()
    }
    
    func fetchFavorites() {
        let request: NSFetchRequest<FavoritePlace> = FavoritePlace.fetchRequest()
        
        do {
            favoritePlaces = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch favorites: \(error)")
        }
    }
    
    func isFavorite(place: Place) -> Bool {
        let request: NSFetchRequest<FavoritePlace> = FavoritePlace.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", place.name)
        
        do {
            return try viewContext.count(for: request) > 0
        } catch {
            print("Failed to check favorite: \(error)")
            return false
        }
    }
    
    func toggleFavorite(place: Place) {
        if isFavorite(place: place) {
            removeFromFavorites(place: place)
        } else {
            saveToFavorites(place: place)
        }
    }
    
    func saveToFavorites(place: Place) {
        let newFavorite = FavoritePlace(context: viewContext)
        newFavorite.name = place.name
        newFavorite.address = place.address
        newFavorite.latitude = place.coordinate.latitude
        newFavorite.longitude = place.coordinate.longitude
        
        do {
            try viewContext.save()
            fetchFavorites()
        } catch {
            print("Failed to save: \(error)")
        }
    }
    
    func removeFromFavorites(place: Place) {
        let request: NSFetchRequest<FavoritePlace> = FavoritePlace.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", place.name)
        
        do {
            let results = try viewContext.fetch(request)
            for object in results {
                viewContext.delete(object)
            }
            try viewContext.save()
            fetchFavorites()
        } catch {
            print("Failed to delete: \(error)")
        }
    }
}

