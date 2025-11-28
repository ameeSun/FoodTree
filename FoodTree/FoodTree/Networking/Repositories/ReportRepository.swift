//
//  ReportRepository.swift
//  TreeBites
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
    /// Returns true if post was deleted, false otherwise
    func submitReport(postId: String, reason: ReportReason, comment: String?) async throws -> Bool {
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
        
        // Check if post should be deleted
        var shouldDelete = false
        
        // If report has a comment/description, delete immediately
        if let comment = comment, !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            shouldDelete = true
            print("🗑️ ReportRepo: Report has comment, deleting post immediately")
        } else {
            // Check if post has 2+ reports without comments
            let reportCount = try await getReportCountWithoutComments(postId: postId)
            if reportCount >= 2 {
                shouldDelete = true
                print("🗑️ ReportRepo: Post has \(reportCount) reports without comments, deleting post")
            }
        }
        
        if shouldDelete {
            let postRepository = FoodPostRepository()
            try await postRepository.deletePost(postId: postId)
            return true
        }
        
        return false
    }
    
    // MARK: - Helpers
    
    /// Get count of reports for a post that have no comment
    private func getReportCountWithoutComments(postId: String) async throws -> Int {
        // Fetch all reports for the post
        let reports: [ReportDTO] = try await supabase.database
            .from("reports")
            .select("*")
            .eq("post_id", value: postId)
            .execute()
            .value
        
        // Count reports where comment is null or empty
        let countWithoutComments = reports.filter { report in
            guard let comment = report.comment else { return true }
            return comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        
        return countWithoutComments
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

