//
//  LocationSearchService.swift
//  TreeBites
//
//  MapKit-based location search service
//

import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
class LocationSearchService: ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    
    private var searchTask: Task<Void, Never>?
    
    func search(query: String, near location: CLLocationCoordinate2D, regionRadius: CLLocationDistance = 5000) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            // Create search request
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: location,
                latitudinalMeters: regionRadius,
                longitudinalMeters: regionRadius
            )
            
            // Perform search
            let search = MKLocalSearch(request: request)
            
            do {
                let response = try await search.start()
                
                if !Task.isCancelled {
                    self.searchResults = response.mapItems
                    self.isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    print("Search error: \(error.localizedDescription)")
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
        
        await searchTask?.value
    }
    
    func cancelSearch() {
        searchTask?.cancel()
        searchResults = []
        isSearching = false
    }
}

