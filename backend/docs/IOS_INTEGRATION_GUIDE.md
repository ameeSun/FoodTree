# iOS Integration Guide

Complete guide for integrating the Supabase backend with the FoodTree iOS app.

## 📦 Step 1: Add Supabase Swift SDK

### Using Swift Package Manager

1. Open Xcode project
2. File > Add Packages...
3. Enter URL: `https://github.com/supabase-community/supabase-swift`
4. Select version: 2.0.0 or later
5. Add to target: FoodTree

### Verify Installation

```swift
import Supabase  // Should compile without errors
```

---

## ⚙️ Step 2: Configure Info.plist

Add Supabase credentials to `Info.plist`:

```xml
<key>SUPABASE_URL</key>
<string>https://duluhjkiqoahshxhiyqz.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1bHVoamtpcW9haHNoeGhpeXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MDg3NjQsImV4cCI6MjA3ODQ4NDc2NH0.x8HqNSpYojZ6iEds6IDZyQtOTx4eswEgqWOA7mFphjg</string>
```

**⚠️ IMPORTANT**: Add these to your `.gitignore` if you create a separate config file. The anon key is safe to embed, but keep it organized.

---

## 📁 Step 3: File Structure

Create the following structure in your Xcode project:

```
FoodTree/FoodTree/
├── Networking/
│   ├── SupabaseConfig.swift          ✅ Created
│   ├── AuthManager.swift              ✅ Created
│   └── Repositories/
│       ├── FoodPostRepository.swift   ✅ Created
│       ├── NotificationRepository.swift    ⚠️  TODO
│       └── OrganizerRepository.swift       ⚠️  TODO
```

The files marked ✅ have been created. Files marked ⚠️  need to be created following the same pattern.

---

## 🔐 Step 4: Implement Remaining Repositories

### NotificationRepository.swift

```swift
import Foundation
import Supabase

@MainActor
class NotificationRepository: ObservableObject {
    private let supabase = SupabaseConfig.shared.client
    
    func fetchNotifications(filter: NotificationFilter = .all) async throws -> [AppNotification] {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        var query = supabase.database
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
        
        switch filter {
        case .unread:
            query = query.eq("is_read", value: false)
        case .type(let notifType):
            query = query.eq("type", value: notifType)
        default:
            break
        }
        
        let dtos: [NotificationDTO] = try await query.execute().value
        return dtos.map { $0.toAppNotification() }
    }
    
    func markAsRead(notificationId: String) async throws {
        try await supabase.database
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: notificationId)
            .execute()
    }
    
    func markAllAsRead() async throws {
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        try await supabase.database
            .from("notifications")
            .update(["is_read": true])
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }
}

struct NotificationDTO: Codable {
    let id: String
    let userId: String
    let type: String
    let title: String
    let body: String?
    let postId: String?
    let data: [String: Any]?
    let isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, title, body
        case postId = "post_id"
        case data
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    func toAppNotification() -> AppNotification {
        let notifType: AppNotification.NotificationType
        switch type {
        case "new_post_nearby": notifType = .newPost
        case "post_low": notifType = .runningLow
        case "post_extended": notifType = .extended
        case "post_nearby": notifType = .nearby
        case "post_expired": notifType = .expired
        default: notifType = .newPost
        }
        
        return AppNotification(
            id: id,
            title: title,
            body: body ?? "",
            timestamp: createdAt,
            type: notifType,
            read: isRead
        )
    }
}

enum NotificationFilter {
    case all
    case unread
    case type(String)
}
```

### OrganizerRepository.swift

```swift
import Foundation
import Supabase

@MainActor
class OrganizerRepository: ObservableObject {
    private let supabase = SupabaseConfig.shared.client
    
    func requestVerification(orgName: String, description: String?, proofUrl: String?) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        let request = VerificationRequestDTO(
            userId: userId.uuidString,
            orgName: orgName,
            orgDescription: description,
            proofUrl: proofUrl
        )
        
        try await supabase.database
            .from("organizer_verification_requests")
            .insert(request)
            .execute()
    }
    
    func fetchVerificationStatus() async throws -> String? {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NetworkError.unauthorized
        }
        
        let request: VerificationRequestDTO? = try? await supabase.database
            .from("organizer_verification_requests")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .single()
            .execute()
            .value
        
        return request?.status
    }
}

struct VerificationRequestDTO: Codable {
    let userId: String
    let orgName: String
    let orgDescription: String?
    let proofUrl: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case orgName = "org_name"
        case orgDescription = "org_description"
        case proofUrl = "proof_url"
        case status
    }
}
```

---

## 🔄 Step 5: Refactor ViewModels

### MapViewModel

Replace `MockData.generatePosts()` with real data:

```swift
class MapViewModel: ObservableObject {
    @Published var posts: [FoodPost] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let repository = FoodPostRepository()
    
    func loadPosts(center: CLLocationCoordinate2D) async {
        isLoading = true
        error = nil
        
        do {
            let filters = PostFilters(
                dietary: Array(self.filters.dietary.map { $0.rawValue }),
                statuses: [],
                verifiedOnly: self.filters.onlyVerified
            )
            
            self.posts = try await repository.fetchNearbyPosts(
                center: center,
                radiusMeters: self.filters.distance * 1609.34, // miles to meters
                filters: filters
            )
        } catch {
            self.error = error.localizedDescription
            print("❌ MapViewModel: Failed to load posts: \(error)")
        }
        
        isLoading = false
    }
}
```

### FeedViewModel

```swift
class FeedViewModel: ObservableObject {
    @Published var posts: [FoodPost] = []
    @Published var isLoading = false
    
    private let repository = FoodPostRepository()
    
    func refresh() async {
        isLoading = true
        
        // Use user's location or default
        let center = LocationManager.shared.userLocation ?? MockData.stanfordCenter
        
        do {
            self.posts = try await repository.fetchNearbyPosts(
                center: center,
                radiusMeters: 5000
            )
        } catch {
            print("❌ FeedViewModel: \(error)")
        }
        
        isLoading = false
    }
    
    func savePost(_ post: FoodPost) {
        Task {
            do {
                _ = try await repository.toggleSavedPost(postId: post.id)
            } catch {
                print("❌ Failed to save post: \(error)")
            }
        }
    }
    
    func hidePost(_ post: FoodPost) {
        posts.removeAll { $0.id == post.id }
        // Could also save to local storage or backend
    }
}
```

### PostComposerViewModel

```swift
class PostComposerViewModel: ObservableObject {
    private let repository = FoodPostRepository()
    
    func publishPost() async throws -> FoodPost {
        // Validate all steps are complete
        guard canProceed else {
            throw NetworkError.invalidData
        }
        
        // Convert photos to Data
        let imageDataArray = photos.map { _ in
            // TODO: Convert UIImage/placeholder to Data
            Data() // Placeholder
        }
        
        let request = CreatePostRequest(
            title: title,
            description: description.isEmpty ? nil : description,
            imageDataArray: imageDataArray,
            dietary: Array(dietaryTags.map { $0.rawValue }),
            perishability: perishability,
            quantityEstimate: quantity,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiryMinutes * 60)),
            location: location ?? MockData.stanfordCenter,
            buildingId: nil, // TODO: Map building name to ID
            buildingName: selectedBuilding,
            pickupInstructions: accessNotes.isEmpty ? nil : accessNotes
        )
        
        return try await repository.createPost(input: request)
    }
}
```

### OrganizerViewModel

```swift
class OrganizerViewModel: ObservableObject {
    @Published var posts: [FoodPost] = []
    
    private let repository = FoodPostRepository()
    
    func loadMyPosts() async {
        do {
            self.posts = try await repository.fetchMyPosts()
        } catch {
            print("❌ OrganizerViewModel: \(error)")
        }
    }
    
    func markAsLow(_ post: FoodPost) {
        Task {
            do {
                try await repository.markAsLow(postId: post.id)
                await loadMyPosts() // Refresh
                FTHaptics.warning()
            } catch {
                print("❌ Failed to mark as low: \(error)")
            }
        }
    }
    
    func adjustQuantity(_ post: FoodPost, to quantity: Int) {
        Task {
            do {
                try await repository.adjustQuantity(postId: post.id, newQuantity: quantity)
                await loadMyPosts()
            } catch {
                print("❌ Failed to adjust quantity: \(error)")
            }
        }
    }
    
    func extendTime(_ post: FoodPost) {
        Task {
            do {
                try await repository.extendPost(postId: post.id, additionalMinutes: 15)
                await loadMyPosts()
            } catch {
                print("❌ Failed to extend time: \(error)")
            }
        }
    }
}
```

---

## 🎯 Step 6: Update AppState

Integrate AuthManager with AppState:

```swift
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var userRole: UserRole = .student
    @Published var notifications: [AppNotification] = []
    
    private let authManager = AuthManager.shared
    private let notificationRepo = NotificationRepository()
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Observe auth state
        Task {
            await authManager.checkSession()
            if authManager.isAuthenticated {
                await loadNotifications()
                updateRoleFromProfile()
            }
        }
    }
    
    private func updateRoleFromProfile() {
        guard let profile = authManager.currentProfile else { return }
        self.userRole = profile.role == "organizer" ? .organizer : .student
    }
    
    private func loadNotifications() async {
        do {
            self.notifications = try await notificationRepo.fetchNotifications()
        } catch {
            print("⚠️  Failed to load notifications: \(error)")
        }
    }
}
```

---

## 📲 Step 7: Handle Deep Links (Magic Link Auth)

### Add URL Scheme

In `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>foodtree</string>
        </array>
    </dict>
</array>
```

### Handle in App

Update `FoodTreeApp.swift`:

```swift
@main
struct FoodTreeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                RootTabView()
                    .environmentObject(appState)
                    .onOpenURL { url in
                        handleAuthCallback(url)
                    }
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
    }
    
    private func handleAuthCallback(_ url: URL) {
        Task {
            do {
                try await AuthManager.shared.handleAuthCallback(url: url)
            } catch {
                print("❌ Auth callback failed: \(error)")
            }
        }
    }
}
```

---

## 🧪 Step 8: Testing

### Unit Tests

Create `FoodTreeTests/RepositoryTests.swift`:

```swift
import XCTest
@testable import FoodTree

class RepositoryTests: XCTestCase {
    func testFetchNearbyPosts() async throws {
        let repo = FoodPostRepository()
        let posts = try await repo.fetchNearbyPosts(
            center: MockData.stanfordCenter,
            radiusMeters: 5000
        )
        
        XCTAssertFalse(posts.isEmpty, "Should fetch posts")
    }
    
    func testAuthFlow() async throws {
        let auth = AuthManager.shared
        
        // Note: This requires test auth credentials
        try await auth.signInWithEmail("test@stanford.edu")
        
        // Would normally verify OTP here
    }
}
```

### Integration Test Checklist

- [ ] Auth: Sign in with Stanford email
- [ ] Auth: Verify OTP code
- [ ] Auth: Session persists after app restart
- [ ] Posts: Fetch nearby posts
- [ ] Posts: Create new post with images
- [ ] Posts: Toggle "On My Way"
- [ ] Posts: Save/unsave post
- [ ] Organizer: Mark post as low/gone
- [ ] Organizer: Adjust quantity
- [ ] Organizer: Extend time
- [ ] Notifications: Fetch and mark as read
- [ ] Storage: Upload images successfully

---

## 🚀 Step 9: Deployment Checklist

### Pre-Production

- [ ] Remove all `MockData` usage from production code paths
- [ ] Add proper error handling UI (toasts, alerts)
- [ ] Implement loading states throughout
- [ ] Add retry logic for failed network requests
- [ ] Test on physical device (not simulator)
- [ ] Verify image uploads work with real photos
- [ ] Test auth flow end-to-end with real Stanford email
- [ ] Verify RLS policies work correctly
- [ ] Test offline behavior (graceful degradation)
- [ ] Add analytics/crash reporting (optional)

### Production

- [ ] Create production Supabase project (if different from dev)
- [ ] Update Info.plist with production URL/keys
- [ ] Enable auth email templates in Supabase Dashboard
- [ ] Configure custom SMTP for branded emails (optional)
- [ ] Set up monitoring/alerts
- [ ] Deploy edge functions to production
- [ ] Set up cron jobs in production
- [ ] Test storage bucket policies
- [ ] Submit to App Store

---

## 🐛 Common Issues

### Issue: "Supabase module not found"

**Solution**: Verify SPM package is added correctly. Clean build folder (Cmd+Shift+K) and rebuild.

### Issue: "Unauthorized" errors

**Solution**: Check that user is logged in (`AuthManager.shared.isAuthenticated`). Verify RLS policies in Supabase Dashboard.

### Issue: Images not uploading

**Solution**: 
1. Verify storage bucket exists
2. Check storage policies
3. Verify image data is valid
4. Check file size < 5MB

### Issue: Posts not appearing

**Solution**:
1. Check network connectivity
2. Verify posts exist in database
3. Check post status (should be "available" or "low")
4. Verify location is within search radius

### Issue: Realtime not working

**Solution**:
1. Verify realtime is enabled in Supabase project settings
2. Check that tables are added to publication
3. Implement realtime subscriptions in iOS (not covered in this guide)

---

## 📚 Next Steps

1. **Implement remaining repositories** (NotificationRepository, OrganizerRepository)
2. **Refactor all ViewModels** to use repositories
3. **Add proper error handling UI** (toasts, alerts)
4. **Implement realtime subscriptions** for live updates
5. **Add image picker integration** for real photo uploads
6. **Implement push notifications** (APNs)
7. **Add comprehensive testing**
8. **Performance optimization** (caching, pagination)

---

## 🆘 Getting Help

- Check Supabase Swift docs: https://github.com/supabase-community/supabase-swift
- Supabase Discord: https://discord.supabase.com
- FoodTree backend docs: See `/backend/README.md`

---

**Integration Status**: 🟡 Core infrastructure complete, ViewModels need refactoring

**Estimated Time to Complete**: 2-4 hours for experienced iOS developer

**Built for Stanford with ❤️**

