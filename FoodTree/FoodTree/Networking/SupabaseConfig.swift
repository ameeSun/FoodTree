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
                    autoRefreshToken: true,
                    persistSession: true,
                    detectSessionInURL: true
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
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            return "" // Will trigger fatalError in SupabaseConfig
        }
        return url
    }
    
    /// Supabase anon key (safe to embed in client)
    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            return "" // Will trigger fatalError in SupabaseConfig
        }
        return key
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

