import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String
    var fullName: String?
    var role: UserRole
    var isVerifiedOrganizer: Bool
    var avatarUrl: String?
    var dietaryPreferences: [String]
    var searchRadiusMiles: Double
    var notificationPreferences: [String: Bool]
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case isVerifiedOrganizer = "is_verified_organizer"
        case avatarUrl = "avatar_url"
        case dietaryPreferences = "dietary_preferences"
        case searchRadiusMiles = "search_radius_miles"
        case notificationPreferences = "notification_preferences"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
