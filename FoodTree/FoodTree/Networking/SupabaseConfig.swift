import Foundation
import Supabase

/// Configuration error for missing Supabase credentials
enum SupabaseConfigError: LocalizedError {
    case missingURL
    case missingAnonKey
    case invalidURL(String)
    
    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Supabase URL is missing. Please configure SUPABASE_URL in Info.plist."
        case .missingAnonKey:
            return "Supabase anonymous key is missing. Please configure SUPABASE_ANON_KEY in Info.plist."
        case .invalidURL(let url):
            return "Invalid Supabase URL format: \(url)"
        }
    }
}

struct SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        // Read configuration from Info.plist
        // Production apps should ensure these values are set in Xcode build settings
        // via INFOPLIST_KEY_SUPABASE_URL and INFOPLIST_KEY_SUPABASE_ANON_KEY
        
        var urlString = Config.supabaseURL
        var key = Config.supabaseAnonKey
        
        // Debug: Print what we found
        #if DEBUG
        print("🔍 Config Debug:")
        print("   URL found: \(!urlString.isEmpty) - '\(urlString.prefix(50))...'")
        print("   Key found: \(!key.isEmpty) - '\(key.prefix(20))...'")
        if let allKeys = Bundle.main.infoDictionary?.keys {
            let supabaseKeys = Array(allKeys).sorted().filter { $0.contains("SUPABASE") }
            print("   Available SUPABASE keys: \(supabaseKeys)")
            if supabaseKeys.isEmpty {
                print("   All Info.plist keys: \(Array(allKeys).sorted().prefix(20))")
            }
        }
        #endif
        
        // Fallback for development if values are missing
        // This ensures the app can run during development
        if urlString.isEmpty {
            #if DEBUG
            print("⚠️ WARNING: Using hardcoded fallback URL. Info.plist values not found!")
            urlString = "https://duluhjkiqoahshxhiyqz.supabase.co"
            #else
            // In production, we should fail if URL is missing
            fatalError("""
            ❌ CRITICAL: Supabase URL is missing.
            
            Please ensure INFOPLIST_KEY_SUPABASE_URL is set in Xcode build settings.
            """)
            #endif
        }
        
        if key.isEmpty {
            #if DEBUG
            print("⚠️ WARNING: Using hardcoded fallback key. Info.plist values not found!")
            key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MDg3NjQsImV4cCI6MjA3ODQ4NDc2NH0.x8HqNSpYojZ6iEds6IDZyQtOTx4eswEgqWOA7mFphjg"
            #else
            // In production, we should fail if key is missing
            fatalError("""
            ❌ CRITICAL: Supabase anonymous key is missing.
            
            Please ensure INFOPLIST_KEY_SUPABASE_ANON_KEY is set in Xcode build settings.
            """)
            #endif
        }
        
        guard let url = URL(string: urlString) else {
            fatalError("❌ CRITICAL: Invalid Supabase URL format: \(urlString)")
        }
        
        #if DEBUG
        print("✅ Supabase client initialized with URL: \(url.absoluteString)")
        #endif
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
}

// MARK: - Configuration Helper
struct Config {
    /// Retrieves Supabase URL from Info.plist
    /// When using GENERATE_INFOPLIST_FILE, Xcode strips the INFOPLIST_KEY_ prefix
    /// So INFOPLIST_KEY_SUPABASE_URL becomes SUPABASE_URL in the generated Info.plist
    static var supabaseURL: String {
        // Try to read from Info.plist
        // Xcode strips INFOPLIST_KEY_ prefix when generating Info.plist
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !url.isEmpty {
            return url
        }
        
        // Fallback: try with prefix (in case of manual Info.plist)
        if let url = Bundle.main.object(forInfoDictionaryKey: "INFOPLIST_KEY_SUPABASE_URL") as? String, !url.isEmpty {
            return url
        }
        
        // Debug: Print all keys to help diagnose
        #if DEBUG
        if let allKeys = Bundle.main.infoDictionary?.keys {
            print("🔍 Available Info.plist keys: \(Array(allKeys).sorted())")
        }
        // Temporary fallback for development - REMOVE IN PRODUCTION
        print("⚠️ WARNING: Using hardcoded fallback URL. Info.plist values not found!")
        return "https://duluhjkiqoahshxhiyqz.supabase.co"
        #else
        return ""
        #endif
    }
    
    /// Retrieves Supabase anonymous key from Info.plist
    /// When using GENERATE_INFOPLIST_FILE, Xcode strips the INFOPLIST_KEY_ prefix
    /// So INFOPLIST_KEY_SUPABASE_ANON_KEY becomes SUPABASE_ANON_KEY in the generated Info.plist
    static var supabaseAnonKey: String {
        // Try to read from Info.plist
        // Xcode strips INFOPLIST_KEY_ prefix when generating Info.plist
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        
        // Fallback: try with prefix (in case of manual Info.plist)
        if let key = Bundle.main.object(forInfoDictionaryKey: "INFOPLIST_KEY_SUPABASE_ANON_KEY") as? String, !key.isEmpty {
            return key
        }
        
        #if DEBUG
        // Temporary fallback for development - REMOVE IN PRODUCTION
        print("⚠️ WARNING: Using hardcoded fallback key. Info.plist values not found!")
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MDg3NjQsImV4cCI6MjA3ODQ4NDc2NH0.x8HqNSpYojZ6iEds6IDZyQtOTx4eswEgqWOA7mFphjg"
        #else
        return ""
        #endif
    }
}

