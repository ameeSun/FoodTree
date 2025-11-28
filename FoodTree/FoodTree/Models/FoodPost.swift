//
//  FoodPost.swift
//  TreeBites
//
//  Core data models for food posts
//

import Foundation
import CoreLocation

// MARK: - Food Post
struct FoodPost: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let images: [String] // URLs or asset names
    let createdAt: Date
    var expiresAt: Date?
    let perishability: Perishability
    let dietary: [DietaryTag]
    var quantityApprox: Int // 0-100
    var status: PostStatus
    let location: PostLocation
    let organizer: Organizer
    var metrics: PostMetrics
    
    enum Perishability: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "Keeps well"
            case .medium: return "Perishable"
            case .high: return "Very perishable"
            }
        }
        
        var color: String {
            switch self {
            case .low: return "state/success"
            case .medium: return "state/warn"
            case .high: return "state/error"
            }
        }
    }
    
    enum PostStatus: String, CaseIterable {
        case available = "available"
        case low = "low"
        case gone = "gone"
        case expired = "expired"
        
        var displayName: String {
            switch self {
            case .available: return "Available"
            case .low: return "Low"
            case .gone: return "Gone"
            case .expired: return "Expired"
            }
        }
    }
    
    // Time remaining in minutes
    var timeRemaining: Int? {
        guard let expiresAt = expiresAt else { return nil }
        let seconds = expiresAt.timeIntervalSince(Date())
        return max(0, Int(seconds / 60))
    }
    
    // Auto-compute status based on time and quantity
    mutating func updateStatus() {
        if let expiresAt = expiresAt, Date() > expiresAt {
            status = .expired
        } else if quantityApprox <= 0 {
            status = .gone
        } else if quantityApprox < 20 {
            status = .low
        } else {
            status = .available
        }
    }
}

// MARK: - Supporting Types
struct PostLocation: Equatable {
    let lat: Double
    let lng: Double
    let building: String?
    let notes: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    func distance(from userLocation: CLLocationCoordinate2D) -> Double {
        let postLocation = CLLocation(latitude: lat, longitude: lng)
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        return userCLLocation.distance(from: postLocation) / 1609.34 // meters to miles
    }
}

struct Organizer: Equatable {
    let id: String
    let name: String
    let verified: Bool
    let avatarUrl: String?
}

struct PostMetrics: Equatable {
    var views: Int
    var onMyWay: Int
    var saves: Int
}

enum DietaryTag: String, CaseIterable, Identifiable {
    case vegan = "vegan"
    case vegetarian = "vegetarian"
    case halal = "halal"
    case kosher = "kosher"
    case glutenFree = "glutenfree"
    case dairyFree = "dairyfree"
    case containsNuts = "nuts"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .vegan: return "Vegan"
        case .vegetarian: return "Vegetarian"
        case .halal: return "Halal"
        case .kosher: return "Kosher"
        case .glutenFree: return "Gluten-free"
        case .dairyFree: return "Dairy-free"
        case .containsNuts: return "Contains nuts"
        }
    }
    
    var icon: String {
        switch self {
        case .vegan: return "leaf.fill"
        case .vegetarian: return "carrot.fill"
        case .halal: return "moon.fill"
        case .kosher: return "star.fill"
        case .glutenFree: return "crown.fill"
        case .dairyFree: return "drop.fill"
        case .containsNuts: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Notification
struct AppNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let timestamp: Date
    let type: NotificationType
    var read: Bool = false
    
    enum NotificationType {
        case newPost
        case runningLow
        case extended
        case nearby
        case expired
    }
}

