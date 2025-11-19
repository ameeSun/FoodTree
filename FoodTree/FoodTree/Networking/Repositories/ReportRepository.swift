//
//  ReportRepository.swift
//  FoodTree
//
//  Repository for reporting posts
//

import Foundation
import Supabase
import Combine

@MainActor
class ReportRepository: ObservableObject {
    private let supabase = SupabaseConfig.shared.client
    
    // MARK: - Submit Report
    
    /// Submit a report for a food post
    func submitReport(postId: String, reason: ReportReason, comment: String?) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        // Map Swift enum to database enum string
        let reasonString: String
        switch reason {
        case .spam:
            reasonString = "spam"
        case .unsafe:
            reasonString = "unsafe_food"
        case .wrongLocation:
            reasonString = "misleading"
        case .inappropriate:
            reasonString = "other"
        case .other:
            reasonString = "other"
        }
        
        let report = ReportDTO(
            postId: postId,
            reporterId: userId.uuidString,
            reason: reasonString,
            comment: comment
        )
        
        try await supabase.database
            .from("reports")
            .insert(report)
            .execute()
        
        print("✅ ReportRepo: Report submitted for post \(postId)")
    }
}

// MARK: - Report Reason Enum

enum ReportReason: String, CaseIterable {
    case spam = "Spam or misleading"
    case unsafe = "Food safety concern"
    case wrongLocation = "Wrong location"
    case inappropriate = "Inappropriate content"
    case other = "Other"
}

// MARK: - Data Transfer Objects

struct ReportDTO: Codable {
    let postId: String
    let reporterId: String
    let reason: String
    let comment: String?
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case reporterId = "reporter_id"
        case reason
        case comment
    }
}

