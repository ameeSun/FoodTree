//
//  SupabaseConfig.swift
//  FoodTree
//
//  Supabase client configuration
//  IMPORTANT: Add Supabase Swift SDK via SPM: https://github.com/supabase-community/supabase-swift
//

import Foundation
import Supabase

/// Configuration for Supabase connection
/// Keys are read from Info.plist (NEVER hardcode sensitive keys)
struct SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        // Read configuration from Info.plist
        guard let url = URL(string: Config.supabaseURL) else {
            fatalError("Invalid SUPABASE_URL in Info.plist")
        }
        
        guard !Config.supabaseAnonKey.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    autoRefreshToken: true
                )
            )
        )
        
        print("✅ Supabase configured: \(url.absoluteString)")
    }
}

/// Helper to read configuration from Info.plist
struct Config {
    /// Supabase project URL
    static var supabaseURL: String {
        // Try reading from Info.plist (works with GENERATE_INFOPLIST_FILE)
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty {
            return url
        }
        
        // Fallback: Hardcoded values (temporary - should be in Info.plist)
        // These match the values in project.pbxproj INFOPLIST_KEY entries
        return "https://duluhjkiqoahshxhiyqz.supabase.co"
    }
    
    /// Supabase anon key (safe to embed in client)
    static var supabaseAnonKey: String {
        // Try reading from Info.plist (works with GENERATE_INFOPLIST_FILE)
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        
        // Fallback: Hardcoded values (temporary - should be in Info.plist)
        // These match the values in project.pbxproj INFOPLIST_KEY entries
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MDg3NjQsImV4cCI6MjA3ODQ4NDc2NH0.x8HqNSpYojZ6iEds6IDZyQtOTx4eswEgqWOA7mFphjg"
    }
}

// MARK: - Error Types

enum NetworkError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError
    case networkFailure
    case invalidData
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You must be logged in to perform this action"
        case .notFound:
            return "The requested resource was not found"
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError:
            return "Failed to parse server response"
        case .networkFailure:
            return "Network connection failed"
        case .invalidData:
            return "Invalid data provided"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

