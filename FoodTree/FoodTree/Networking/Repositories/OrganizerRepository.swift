//
//  OrganizerRepository.swift
//  TreeBites
//
//  Repository for organizer-specific operations
//

import Foundation
import Observation
import Combine
import Supabase

@MainActor
class OrganizerRepository: ObservableObject {
    
    private let supabase = SupabaseConfig.shared.client
    
    // MARK: - Verification Requests
    
    /// Request organizer verification
    func requestVerification(orgName: String, description: String?, proofUrl: String?) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        let request = VerificationRequestDTO(
            userId: userId.uuidString,
            orgName: orgName,
            orgDescription: description,
            proofUrl: proofUrl,
            status: nil
        )
        
        try await supabase.database
            .from("organizer_verification_requests")
            .insert(request)
            .execute()
        
        print("✅ OrganizerRepo: Verification request submitted")
    }
    
    /// Fetch current user's verification status
    func fetchVerificationStatus() async throws -> VerificationStatus? {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        // Fetch most recent verification request
        let requests: [VerificationRequestDTO] = try await supabase.database
            .from("organizer_verification_requests")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        guard let latestRequest = requests.first,
              let statusString = latestRequest.status else {
            return nil // No verification request found
        }
        
        return VerificationStatus(rawValue: statusString)
    }
    
    // MARK: - My Posts
    
    /// Fetch posts created by current user
    /// Note: This delegates to FoodPostRepository.fetchMyPosts() for consistency
    func fetchMyPosts() async throws -> [FoodPost] {
        let repository = FoodPostRepository()
        return try await repository.fetchMyPosts()
    }
}

// MARK: - Verification Status Enum

enum VerificationStatus: String {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

// MARK: - Data Transfer Objects

struct VerificationRequestDTO: Codable {
    let userId: String
    let orgName: String
    let orgDescription: String?
    let proofUrl: String?
    let status: String? // Optional for inserts (defaults to 'pending'), required for reads
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case orgName = "org_name"
        case orgDescription = "org_description"
        case proofUrl = "proof_url"
        case status
    }
}

