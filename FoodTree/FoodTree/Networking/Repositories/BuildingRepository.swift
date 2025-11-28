//
//  BuildingRepository.swift
//  TreeBites
//
//  Repository for campus building queries
//

import Foundation
import CoreLocation
import Combine

#if canImport(Supabase)
import Supabase
#endif

#if canImport(Supabase)
@MainActor
class BuildingRepository: ObservableObject {
    private let supabase = SupabaseConfig.shared.client
    
    // MARK: - Fetch Buildings
    
    /// Fetch all buildings, optionally filtered by search term
    func fetchBuildings(search: String? = nil) async throws -> [StanfordBuilding] {
        // Build query
        var query = supabase.database
            .from("campus_buildings")
            .select()
        
        // Apply search filter if provided (filter client-side for case-insensitive search)
        // Note: PostgREST ilike requires raw SQL, so we filter client-side instead
        let orderedQuery = query.order("name", ascending: true)
        
        // Execute query
        var dtos: [BuildingDTO] = try await orderedQuery
            .execute()
            .value
        
        // Filter client-side for case-insensitive search
        if let search = search, !search.isEmpty {
            let searchLower = search.lowercased()
            dtos = dtos.filter { $0.name.lowercased().contains(searchLower) }
        }
        
        return dtos.map { $0.toStanfordBuilding() }
    }
    
    /// Fetch a single building by code
    func fetchBuilding(byCode code: String) async throws -> StanfordBuilding? {
        let dto: BuildingDTO? = try? await supabase.database
            .from("campus_buildings")
            .select()
            .eq("code", value: code)
            .single()
            .execute()
            .value
        
        return dto?.toStanfordBuilding()
    }
    
    /// Fetch a single building by name
    func fetchBuilding(byName name: String) async throws -> StanfordBuilding? {
        let dto: BuildingDTO? = try? await supabase.database
            .from("campus_buildings")
            .select()
            .eq("name", value: name)
            .single()
            .execute()
            .value
        
        return dto?.toStanfordBuilding()
    }
}
#endif

#if !canImport(Supabase)
@MainActor
class BuildingRepository: ObservableObject {
    // Fallback repository when Supabase module isn't linked for this target (e.g., previews/tests)

    // MARK: - Fetch Buildings
    func fetchBuildings(search: String? = nil) async throws -> [StanfordBuilding] {
        // Return an empty array or provide mock data as needed
        return []
    }

    // MARK: - Fetch by Code
    func fetchBuilding(byCode code: String) async throws -> StanfordBuilding? {
        return nil
    }

    // MARK: - Fetch by Name
    func fetchBuilding(byName name: String) async throws -> StanfordBuilding? {
        return nil
    }
}
#endif

// MARK: - Data Transfer Objects

struct BuildingDTO: Codable {
    let id: Int
    let code: String
    let name: String
    let latitude: Double?
    let longitude: Double?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case latitude
        case longitude
        case notes
    }
    
    func toStanfordBuilding() -> StanfordBuilding {
        // Use provided coordinates or default Stanford center if missing
        let lat = latitude ?? 37.4275
        let lng = longitude ?? -122.1697
        
        // StanfordBuilding struct from MockData has id as computed property
        // Initialize with name and coordinates
        let building = StanfordBuilding(name: name, lat: lat, lng: lng)
        return building
    }
}

// MARK: - Building Model Extension
// Note: StanfordBuilding is defined in MockData.swift
// We'll map to the existing struct which doesn't include code
// Code can be stored separately if needed



