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
        
        let urlString = Config.supabaseURL
        let key = Config.supabaseAnonKey
        
        // Validate URL
        guard !urlString.isEmpty else {
            fatalError("❌ CRITICAL: Supabase URL is missing. Configure INFOPLIST_KEY_SUPABASE_URL in Xcode build settings.")
        }
        
        guard !key.isEmpty else {
            fatalError("❌ CRITICAL: Supabase anonymous key is missing. Configure INFOPLIST_KEY_SUPABASE_ANON_KEY in Xcode build settings.")
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
    /// Checks both SUPABASE_URL and INFOPLIST_KEY_SUPABASE_URL keys
    static var supabaseURL: String {
        // Try to read from Info.plist
        // Xcode automatically prefixes keys with INFOPLIST_KEY_ when set in build settings
        let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "INFOPLIST_KEY_SUPABASE_URL") as? String 
            ?? ""
        
        return url
    }
    
    /// Retrieves Supabase anonymous key from Info.plist
    /// Checks both SUPABASE_ANON_KEY and INFOPLIST_KEY_SUPABASE_ANON_KEY keys
    static var supabaseAnonKey: String {
        // Try to read from Info.plist
        // Xcode automatically prefixes keys with INFOPLIST_KEY_ when set in build settings
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "INFOPLIST_KEY_SUPABASE_ANON_KEY") as? String 
            ?? ""
        
        return key
    }
}

