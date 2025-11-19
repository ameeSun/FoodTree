import Foundation
import Supabase

struct SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        // Read from Info.plist
        // Note: In a real app, you might want to use a more secure way to store keys if possible,
        // but for this prototype, Info.plist or a Config struct is fine.
        // We will use a Config struct approach for better type safety and easy swapping.
        
        print("🔧 DEBUG: Initializing SupabaseConfig...")
        print("🔧 DEBUG: All Info.plist keys: \(Bundle.main.infoDictionary?.keys.sorted() ?? [])")
        
        let urlString = Config.supabaseURL
        let key = Config.supabaseAnonKey
        
        print("🔧 DEBUG: URL String: '\(urlString)'")
        print("🔧 DEBUG: Key length: \(key.count)")
        
        guard let url = URL(string: urlString), !urlString.isEmpty, !key.isEmpty else {
            // Fallback for development/preview if keys are missing, to prevent crash
            print("⚠️ WARNING: Supabase credentials missing. Auth will not work.")
            print("⚠️ URL valid: \(URL(string: urlString) != nil), URL empty: \(urlString.isEmpty), Key empty: \(key.isEmpty)")
            self.client = SupabaseClient(supabaseURL: URL(string: "https://placeholder.supabase.co")!, supabaseKey: "placeholder")
            return
        }
        
        print("✅ Supabase client initialized successfully with URL: \(url)")
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
}

// Configuration helper
struct Config {
    static var supabaseURL: String {
        // Try to read from Info.plist first
        let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "INFOPLIST_KEY_SUPABASE_URL") as? String 
            ?? ""
        
        // If Info.plist doesn't have it, use hardcoded value
        let finalURL = url.isEmpty ? "https://duluhjkiqoahshxhiyqz.supabase.co" : url
        
        print("🔍 DEBUG: SUPABASE_URL = '\(finalURL)'")
        return finalURL
    }
    
    static var supabaseAnonKey: String {
        // Try to read from Info.plist first
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String 
            ?? Bundle.main.object(forInfoDictionaryKey: "INFOPLIST_KEY_SUPABASE_ANON_KEY") as? String 
            ?? ""
        
        // If Info.plist doesn't have it, use hardcoded value
        let finalKey = key.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MDg3NjQsImV4cCI6MjA3ODQ4NDc2NH0.x8HqNSpYojZ6iEds6IDZyQtOTx4eswEgqWOA7mFphjg" : key
        
        print("🔍 DEBUG: SUPABASE_ANON_KEY = '\(finalKey.prefix(20))...'")
        return finalKey
    }
}

