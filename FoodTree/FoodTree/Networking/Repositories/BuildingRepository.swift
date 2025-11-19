//
//  BuildingRepository.swift
//  FoodTree
//
//  Repository for campus building queries
//

import Foundation
import Supabase
import CoreLocation

@MainActor
class BuildingRepository: ObservableObject {
    private let supabase = SupabaseConfig.shared.client
    
    // MARK: - Fetch Buildings
    
    /// Fetch all buildings, optionally filtered by search term
    func fetchBuildings(search: String? = nil) async throws -> [StanfordBuilding] {
        var query = supabase.database
            .from("campus_buildings")
            .select()
            .order("name", ascending: true)
        
        // Apply search filter if provided
        if let search = search, !search.isEmpty {
            query = query.ilike("name", pattern: "%\(search)%")
        }
        
        let dtos: [BuildingDTO] = try await query.execute().value
        
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
        var building = StanfordBuilding(name: name, lat: lat, lng: lng)
        return building
    }
}

// MARK: - Building Model Extension
// Note: StanfordBuilding is defined in MockData.swift
// We'll map to the existing struct which doesn't include code
// Code can be stored separately if needed

