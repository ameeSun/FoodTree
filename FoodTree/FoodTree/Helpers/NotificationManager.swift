//
//  NotificationManager.swift
//  TreeBites
//
//  Push notification manager
//

import Foundation
import UserNotifications
import Combine
import UIKit
import Supabase

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotifications: [UNNotificationRequest] = []
    @Published var deviceToken: String?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let supabase = SupabaseConfig.shared.client
    @Published var canUseRemoteNotifications = false
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
        checkRemoteNotificationAvailability()
    }
    
    /// Check if remote notifications are available (requires proper entitlements)
    /// This is a best-effort check - we'll handle errors gracefully even if this check passes
    /// Note: For full push notification support, you need to:
    /// 1. Enable "Push Notifications" capability in Xcode
    /// 2. Add an entitlements file with aps-environment
    /// 3. Configure proper signing with push-enabled provisioning profile
    private func checkRemoteNotificationAvailability() {
        // We'll attempt to register and handle errors gracefully
        // Setting to true initially - will be set to false if registration fails
        canUseRemoteNotifications = true
    }
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                    // Only register for remote notifications if properly configured
                    // This prevents freezing when entitlements are missing
                    self?.registerForRemoteNotificationsSafely()
                } else if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                }
                
                // Update status asynchronously to avoid blocking
                self?.checkAuthorizationStatus()
                
                // Call completion handler - always call even if remote registration fails
                // Local notifications will still work
                completion?(granted)
            }
        }
    }
    
    /// Safely register for remote notifications with proper error handling
    /// This method attempts registration and handles errors gracefully without freezing
    private func registerForRemoteNotificationsSafely() {
        // Register for remote notifications in a safe, non-blocking way
        // The registration itself is asynchronous, but we need to ensure
        // error handling doesn't block the UI thread
        DispatchQueue.main.async { [weak self] in
            // This call is asynchronous and won't block the current thread
            // Errors will be handled in didFailToRegisterForRemoteNotifications
            UIApplication.shared.registerForRemoteNotifications()
            print("📱 Attempting to register for remote notifications...")
            print("   (If this fails, local notifications will still work)")
        }
    }
    
    /// Called when device token is received from APNs
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        
        print("📱 Received device token: \(token.prefix(20))...")
        
        // Store token in database (non-blocking, with retry logic)
        Task {
            await storeDeviceTokenWithRetry(token)
        }
    }
    
    /// Store device token with retry logic in case user isn't authenticated yet
    private func storeDeviceTokenWithRetry(_ token: String, retryCount: Int = 0) async {
        // Maximum 3 retries with increasing delays
        let maxRetries = 3
        let delay: UInt64 = UInt64((retryCount + 1) * 1_000_000_000) // 1s, 2s, 3s
        
        // Wait before attempting (exponential backoff)
        if retryCount > 0 {
            try? await Task.sleep(nanoseconds: delay)
        }
        
        guard let userId = AuthService.shared.currentUser?.id else {
            if retryCount < maxRetries {
                print("⚠️ User not authenticated yet, retrying device token storage in \(retryCount + 1)s...")
                await storeDeviceTokenWithRetry(token, retryCount: retryCount + 1)
            } else {
                print("⚠️ Cannot store device token: No user logged in after \(maxRetries) retries")
            }
            return
        }
        
        do {
            // Check if token already exists
            let existing: [PushTokenDTO]? = try? await supabase.database
                .from("push_tokens")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("token", value: token)
                .execute()
                .value
            
            if existing?.isEmpty ?? true {
                // Insert new token
                let tokenRecord = PushTokenDTO(
                    userId: userId.uuidString,
                    platform: "ios",
                    token: token
                )
                
                try await supabase.database
                    .from("push_tokens")
                    .insert(tokenRecord)
                    .execute()
                
                print("✅ Stored device token in database")
            } else {
                print("ℹ️ Device token already exists in database")
            }
        } catch {
            print("⚠️ Failed to store device token: \(error)")
            // Don't throw - this is non-critical for app functionality
        }
    }
    
    /// Called when remote notification registration fails
    /// This is called asynchronously and should not block the UI
    func didFailToRegisterForRemoteNotifications(error: Error) {
        // Handle error gracefully without blocking
        let errorDescription = error.localizedDescription
        
        // Check for common errors and provide helpful messages
        if errorDescription.contains("aps-environment") {
            print("⚠️ Push Notifications: Missing aps-environment entitlement")
            print("   Local notifications will still work. To enable push notifications:")
            print("   1. Open Xcode > Target > Signing & Capabilities")
            print("   2. Click '+' and add 'Push Notifications' capability")
            print("   3. Ensure your provisioning profile includes push notifications")
        } else {
            print("❌ Failed to register for remote notifications: \(errorDescription)")
        }
        
        // Update flag to prevent future attempts
        canUseRemoteNotifications = false
        
        // Don't block or freeze - local notifications still work
        // The app should continue functioning normally
    }
    
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removePendingNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap (e.g., navigate to post)
        let userInfo = response.notification.request.content.userInfo
        print("📬 Notification tapped: \(userInfo)")
        completionHandler()
    }
}

// MARK: - Push Token DTO
struct PushTokenDTO: Codable {
    let userId: String
    let platform: String
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case platform
        case token
    }
}


