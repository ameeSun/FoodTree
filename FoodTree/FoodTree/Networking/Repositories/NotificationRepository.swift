//
//  NotificationRepository.swift
//  FoodTree
//
//  Repository for notification CRUD operations
//

import Foundation
import Combine
import Supabase

@MainActor
final class NotificationRepository: ObservableObject {
    private let supabase = SupabaseConfig.shared.client
    
    // MARK: - Fetch Notifications
    
    /// Fetch notifications for current user with optional filtering
    func fetchNotifications(filter: NotificationFilter? = nil) async throws -> [AppNotification] {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        var base = supabase.database
            .from("notifications")
            .select("*")
            .eq("user_id", value: userId.uuidString)
        
        if let filter = filter {
            switch filter {
            case .unread:
                base = base.eq("is_read", value: false)
            case .posts:
                base = base.eq("type", value: "new_post_nearby")
            case .updates:
                base = base.in("type", values: ["post_low", "post_gone", "post_expired", "post_extended"])
            case .all:
                break
            }
        }
        
        let dtos: [NotificationDTO] = try await base
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return dtos.compactMap { $0.toAppNotification() }
    }
    
    /// Mark a notification as read
    func markAsRead(notificationId: String) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        // Verify notification belongs to user
        let notification: NotificationDTO = try await supabase.database
            .from("notifications")
            .select("*")
            .eq("id", value: notificationId)
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        // Update is_read
        try await supabase.database
            .from("notifications")
            .update(["is_read": AnyCodable(true), "updated_at": AnyCodable(Date().toISO8601String())])
            .eq("id", value: notificationId)
            .execute()
        
        print("✅ NotificationRepo: Marked notification \(notificationId) as read")
    }
    
    /// Mark all notifications as read for current user
    func markAllAsRead() async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        try await supabase.database
            .from("notifications")
            .update(["is_read": AnyCodable(true), "updated_at": AnyCodable(Date().toISO8601String())])
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
        
        print("✅ NotificationRepo: Marked all notifications as read")
    }
    
    /// Get count of unread notifications
    func getUnreadCount() async throws -> Int {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        let response = try await supabase.database
            .from("notifications")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
        
        return response.count ?? 0
    }
}

// MARK: - Notification Filter

enum NotificationFilter {
    case all
    case unread
    case posts
    case updates
}

// MARK: - Data Transfer Objects

struct NotificationDTO: Codable {
    let id: String
    let userId: String
    let type: String
    let title: String
    let body: String?
    let postId: String?
    let data: [String: AnyCodable]?
    let isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case body
        case postId = "post_id"
        case data
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    func toAppNotification() -> AppNotification? {
        // Map database notification_type to Swift enum
        let notificationType: AppNotification.NotificationType
        switch type {
        case "new_post_nearby":
            notificationType = .newPost
        case "post_low":
            notificationType = .runningLow
        case "post_extended":
            notificationType = .extended
        case "post_expired":
            notificationType = .expired
        case "post_gone":
            notificationType = .runningLow // Map gone to runningLow for now
        default:
            notificationType = .nearby // Fallback
        }
        
        return AppNotification(
            id: id,
            title: title,
            body: body ?? "",
            timestamp: createdAt,
            type: notificationType,
            read: isRead
        )
    }
}

// MARK: - AnyCodable Helper (for JSONB data field)

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode AnyCodable"
                )
            )
        }
    }
}

