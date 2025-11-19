//
//  FoodPostRepository.swift
//  FoodTree
//
//  Repository for food post CRUD operations and queries
//

import Foundation
import Supabase
import CoreLocation
import Combine

@MainActor
class FoodPostRepository: ObservableObject {
    private let supabase = SupabaseConfig.shared.client
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    // MARK: - Fetch Posts
    
    /// Fetch nearby posts with filters
    func fetchNearbyPosts(
        center: CLLocationCoordinate2D,
        radiusMeters: Double = 5000, // ~3 miles
        filters: PostFilters = PostFilters()
    ) async throws -> [FoodPost] {
        // Build query
        var query = supabase.database
            .from("food_posts")
            .select("""
                *,
                creator:profiles!creator_id(id, email, full_name, is_verified_organizer, avatar_url),
                images:food_post_images(id, storage_path, sort_order)
            """)
        
        // Filter by status
        if !filters.statuses.isEmpty {
            query = query.in("status", values: filters.statuses)
        } else {
            query = query.in("status", values: ["available", "low"]) // Default
        }
        
        // Filter by dietary tags
        if !filters.dietary.isEmpty {
            query = query.overlaps("dietary", value: filters.dietary)
        }
        
        // Filter by verified organizers only
        if filters.verifiedOnly {
            // Note: This requires a join, handled in the select above
            // We'll filter client-side for now
        }
        
        // Order by created_at descending - chain order after filters
        let orderedQuery = query.order("created_at", ascending: false)
        
        // Execute query
        let response: [FoodPostDTO] = try await orderedQuery.execute().value
        
        // Convert DTOs to domain models
        var posts = response.compactMap { dto -> FoodPost? in
            dto.toFoodPost()
        }
        
        // Client-side filtering for distance and verified
        posts = posts.filter { post in
            let distance = post.location.distance(from: center)
            let withinRadius = distance <= (radiusMeters / 1609.34) // meters to miles
            let meetsVerifiedCriteria = !filters.verifiedOnly || post.organizer.verified
            return withinRadius && meetsVerifiedCriteria
        }
        
        // Sort by distance
        posts.sort { post1, post2 in
            let dist1 = post1.location.distance(from: center)
            let dist2 = post2.location.distance(from: center)
            return dist1 < dist2
        }
        
        print("✅ FoodPostRepo: Fetched \(posts.count) nearby posts")
        return posts
    }
    
    /// Fetch a single post by ID
    func fetchPost(id: String) async throws -> FoodPost {
        let dto: FoodPostDTO = try await supabase.database
            .from("food_posts")
            .select("""
                *,
                creator:profiles!creator_id(id, email, full_name, is_verified_organizer, avatar_url),
                images:food_post_images(id, storage_path, sort_order)
            """)
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        guard let post = dto.toFoodPost() else {
            throw NetworkError.decodingError
        }
        
        // Increment view count
        await incrementViews(postId: id)
        
        return post
    }
    
    // MARK: - Create Post
    
    /// Create a new food post with images
    func createPost(input: CreatePostRequest) async throws -> FoodPost {
        guard let creatorId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        // 1. Upload images to storage
        var uploadedPaths: [(path: String, sortOrder: Int)] = []
        for (index, imageData) in input.imageDataArray.enumerated() {
            let path = "post/\(creatorId.uuidString)/\(UUID().uuidString)/\(UUID().uuidString).jpg"
            
            do {
                _ = try await supabase.storage
                    .from("food-images")
                    .upload(
                        path,
                        data: imageData,
                        options: FileOptions(contentType: "image/jpeg")
                    )
                
                uploadedPaths.append((path, index))
            } catch {
                print("⚠️  Failed to upload image \(index): \(error)")
                // Continue with other images
            }
        }
        
        guard !uploadedPaths.isEmpty else {
            throw NetworkError.serverError("Failed to upload any images")
        }
        
        // 2. Create post record
        let newPost = NewPostDTO(
            creatorId: creatorId.uuidString,
            title: input.title,
            description: input.description,
            dietary: input.dietary,
            perishability: input.perishability.rawValue,
            quantityEstimate: input.quantityEstimate,
            expiresAt: input.expiresAt?.toISO8601String(),
            locationLat: input.location.latitude,
            locationLng: input.location.longitude,
            buildingId: input.buildingId,
            buildingName: input.buildingName,
            pickupInstructions: input.pickupInstructions
        )
        
        let createdPost: FoodPostDTO = try await supabase.database
            .from("food_posts")
            .insert(newPost)
            .select("""
                *,
                creator:profiles!creator_id(id, email, full_name, is_verified_organizer, avatar_url)
            """)
            .single()
            .execute()
            .value
        
        // 3. Create image records
        let imageRecords = uploadedPaths.map { item in
            NewImageDTO(
                postId: createdPost.id,
                storagePath: item.path,
                sortOrder: item.sortOrder
            )
        }
        
        try await supabase.database
            .from("food_post_images")
            .insert(imageRecords)
            .execute()
        
        // 4. Fetch complete post with images
        let completePost = try await fetchPost(id: createdPost.id)
        
        print("✅ FoodPostRepo: Created post '\(input.title)'")
        
        // TODO: Trigger nearby user notifications via edge function
        // await triggerNearbyNotifications(post: completePost)
        
        return completePost
    }
    
    // MARK: - Update Post
    
    /// Mark post as low
    func markAsLow(postId: String) async throws {
        try await updatePostStatus(postId: postId, status: "low")
    }
    
    /// Mark post as gone
    func markAsGone(postId: String) async throws {
        try await updatePostStatus(postId: postId, status: "gone")
    }
    
    /// Adjust quantity
    func adjustQuantity(postId: String, newQuantity: Int) async throws {
        struct UpdatePayload: Codable {
            let quantity_estimate: Int
            let updated_at: String
        }
        
        let payload = UpdatePayload(
            quantity_estimate: newQuantity,
            updated_at: Date().toISO8601String()
        )
        
        try await supabase.database
            .from("food_posts")
            .update(payload)
            .eq("id", value: postId)
            .execute()
        
        print("✅ FoodPostRepo: Adjusted quantity for \(postId)")
    }
    
    /// Extend post expiration time
    func extendPost(postId: String, additionalMinutes: Int) async throws {
        // Fetch current expiration
        let post: FoodPostDTO = try await supabase.database
            .from("food_posts")
            .select("expires_at")
            .eq("id", value: postId)
            .single()
            .execute()
            .value
        
        guard let currentExpiry = post.expiresAt else {
            throw NetworkError.invalidData
        }
        
        let newExpiry = currentExpiry.addingTimeInterval(TimeInterval(additionalMinutes * 60))
        
        try await supabase.database
            .from("food_posts")
            .update(["expires_at": newExpiry.toISO8601String(), "updated_at": Date().toISO8601String()])
            .eq("id", value: postId)
            .execute()
        
        print("✅ FoodPostRepo: Extended post \(postId) by \(additionalMinutes) min")
    }
    
    private func updatePostStatus(postId: String, status: String) async throws {
        try await supabase.database
            .from("food_posts")
            .update(["status": status, "updated_at": Date().toISO8601String()])
            .eq("id", value: postId)
            .execute()
        
        print("✅ FoodPostRepo: Updated post \(postId) to \(status)")
    }
    
    // MARK: - User Actions
    
    /// Toggle "On My Way" status
    func toggleOnMyWay(postId: String, etaMinutes: Int? = nil) async throws -> Bool {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        // Check if already marked
        let existing: [OnMyWayDTO]? = try? await supabase.database
            .from("on_my_way")
            .select()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if existing?.isEmpty == false {
            // Remove on my way
            try await supabase.database
                .from("on_my_way")
                .delete()
                .eq("post_id", value: postId)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            print("✅ FoodPostRepo: Removed on my way for \(postId)")
            return false
        } else {
            // Add on my way
            let record = OnMyWayDTO(
                postId: postId,
                userId: userId.uuidString,
                etaMinutes: etaMinutes
            )
            
            try await supabase.database
                .from("on_my_way")
                .insert(record)
                .execute()
            
            print("✅ FoodPostRepo: Added on my way for \(postId)")
            return true
        }
    }
    
    /// Save/unsave a post
    func toggleSavedPost(postId: String) async throws -> Bool {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        // Check if already saved
        let existing: [SavedPostDTO]? = try? await supabase.database
            .from("saved_posts")
            .select()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if existing?.isEmpty == false {
            // Unsave
            try await supabase.database
                .from("saved_posts")
                .delete()
                .eq("post_id", value: postId)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            return false
        } else {
            // Save
            let record = SavedPostDTO(postId: postId, userId: userId.uuidString)
            
            try await supabase.database
                .from("saved_posts")
                .insert(record)
                .execute()
            
            return true
        }
    }
    
    /// Fetch user's saved posts
    func fetchSavedPosts() async throws -> [FoodPost] {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        // Fetch saved post IDs
        let saved: [SavedPostDTO] = try await supabase.database
            .from("saved_posts")
            .select("post_id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let postIds = saved.map { $0.postId }
        
        guard !postIds.isEmpty else { return [] }
        
        // Fetch posts
        let dtos: [FoodPostDTO] = try await supabase.database
            .from("food_posts")
            .select("""
                *,
                creator:profiles!creator_id(id, email, full_name, is_verified_organizer, avatar_url),
                images:food_post_images(id, storage_path, sort_order)
            """)
            .in("id", values: postIds)
            .execute()
            .value
        
        return dtos.compactMap { $0.toFoodPost() }
    }
    
    // MARK: - Organizer Methods
    
    /// Fetch posts created by current user
    func fetchMyPosts() async throws -> [FoodPost] {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        let dtos: [FoodPostDTO] = try await supabase.database
            .from("food_posts")
            .select("""
                *,
                creator:profiles!creator_id(id, email, full_name, is_verified_organizer, avatar_url),
                images:food_post_images(id, storage_path, sort_order)
            """)
            .eq("creator_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return dtos.compactMap { $0.toFoodPost() }
    }
    
    // MARK: - Helpers
    
    private func incrementViews(postId: String) async {
        do {
            try await supabase.database.rpc(
                "increment_post_views",
                params: ["post_uuid": postId]
            ).execute()
        } catch {
            print("⚠️  Failed to increment views: \(error)")
        }
    }
}

// MARK: - Data Transfer Objects (DTOs)

struct FoodPostDTO: Codable {
    let id: String
    let creatorId: String
    let title: String
    let description: String?
    let tags: [String]?
    let dietary: [String]?
    let perishability: String
    let quantityEstimate: Int
    let status: String
    let expiresAt: Date?
    let autoExpires: Bool
    let locationLat: Double
    let locationLng: Double
    let buildingId: Int?
    let buildingName: String?
    let pickupInstructions: String?
    let viewsCount: Int
    let onMyWayCount: Int
    let savesCount: Int
    let createdAt: Date
    let updatedAt: Date
    let creator: ProfileDTO?
    let images: [ImageDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, tags, dietary, perishability, status
        case creatorId = "creator_id"
        case quantityEstimate = "quantity_estimate"
        case expiresAt = "expires_at"
        case autoExpires = "auto_expires"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case buildingId = "building_id"
        case buildingName = "building_name"
        case pickupInstructions = "pickup_instructions"
        case viewsCount = "views_count"
        case onMyWayCount = "on_my_way_count"
        case savesCount = "saves_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creator, images
    }
    
    func toFoodPost() -> FoodPost? {
        guard let creator = creator else { return nil }
        
        // Convert dietary tags
        let dietaryTags = (dietary ?? []).compactMap { DietaryTag(rawValue: $0) }
        
        // Convert perishability
        guard let perishLevel = FoodPost.Perishability(rawValue: perishability) else {
            return nil
        }
        
        // Convert status
        guard let postStatus = FoodPost.PostStatus(rawValue: status) else {
            return nil
        }
        
        // Convert images to URLs
        let imageUrls = (images ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { img -> String? in
                // Generate public URL from storage path
                return "https://duluhjkiqoahshxhiyqz.supabase.co/storage/v1/object/public/food-images/\(img.storagePath)"
            }
        
        return FoodPost(
            id: id,
            title: title,
            description: description,
            images: imageUrls.isEmpty ? ["placeholder"] : imageUrls,
            createdAt: createdAt,
            expiresAt: expiresAt,
            perishability: perishLevel,
            dietary: dietaryTags,
            quantityApprox: quantityEstimate,
            status: postStatus,
            location: PostLocation(
                lat: locationLat,
                lng: locationLng,
                building: buildingName,
                notes: pickupInstructions
            ),
            organizer: Organizer(
                id: creator.id,
                name: creator.fullName ?? creator.email,
                verified: creator.isVerifiedOrganizer,
                avatarUrl: creator.avatarUrl
            ),
            metrics: PostMetrics(
                views: viewsCount,
                onMyWay: onMyWayCount,
                saves: savesCount
            )
        )
    }
}

struct ProfileDTO: Codable {
    let id: String
    let email: String
    let fullName: String?
    let isVerifiedOrganizer: Bool
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case isVerifiedOrganizer = "is_verified_organizer"
        case avatarUrl = "avatar_url"
    }
}

struct ImageDTO: Codable {
    let id: String
    let storagePath: String
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case storagePath = "storage_path"
        case sortOrder = "sort_order"
    }
}

struct NewPostDTO: Codable {
    let creatorId: String
    let title: String
    let description: String?
    let dietary: [String]
    let perishability: String
    let quantityEstimate: Int
    let expiresAt: String?
    let locationLat: Double
    let locationLng: Double
    let buildingId: Int?
    let buildingName: String?
    let pickupInstructions: String?
    
    enum CodingKeys: String, CodingKey {
        case creatorId = "creator_id"
        case title, description, dietary, perishability
        case quantityEstimate = "quantity_estimate"
        case expiresAt = "expires_at"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case buildingId = "building_id"
        case buildingName = "building_name"
        case pickupInstructions = "pickup_instructions"
    }
}

struct NewImageDTO: Codable {
    let postId: String
    let storagePath: String
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case storagePath = "storage_path"
        case sortOrder = "sort_order"
    }
}

struct OnMyWayDTO: Codable {
    let postId: String
    let userId: String
    let etaMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case etaMinutes = "eta_minutes"
    }
}

struct SavedPostDTO: Codable {
    let postId: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
    }
}

// MARK: - Request Models

struct CreatePostRequest {
    let title: String
    let description: String?
    let imageDataArray: [Data]
    let dietary: [String]
    let perishability: FoodPost.Perishability
    let quantityEstimate: Int
    let expiresAt: Date?
    let location: CLLocationCoordinate2D
    let buildingId: Int?
    let buildingName: String?
    let pickupInstructions: String?
}

struct PostFilters {
    var dietary: [String] = []
    var statuses: [String] = []
    var verifiedOnly: Bool = false
}

