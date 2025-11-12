//
//  Extensions.swift
//  FoodTree
//
//  Useful Swift and SwiftUI extensions
//

import SwiftUI
import CoreLocation

// MARK: - Date Extensions
extension Date {
    func timeAgoDisplay() -> String {
        let seconds = Date().timeIntervalSince(self)
        let minutes = Int(seconds / 60)
        
        if minutes < 1 {
            return "Just now"
        } else if minutes == 1 {
            return "1 min ago"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else {
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours)h ago"
            } else {
                let days = hours / 24
                return "\(days)d ago"
            }
        }
    }
    
    func minutesUntil() -> Int {
        let seconds = self.timeIntervalSince(Date())
        return max(0, Int(seconds / 60))
    }
}

// MARK: - CLLocationCoordinate2D Extensions
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - View Extensions
extension View {
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - String Extensions
extension String {
    var isNotEmpty: Bool {
        !self.isEmpty
    }
}

// MARK: - Collection Extensions
extension Collection {
    /// Safe subscript access
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Optional Extensions
extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

// MARK: - Environment Keys
struct IsReduceMotionEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isReduceMotionEnabled: Bool {
        get { self[IsReduceMotionEnabledKey.self] }
        set { self[IsReduceMotionEnabledKey.self] = newValue }
    }
}

// MARK: - Preference Keys
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Number Formatting
extension Int {
    var abbreviated: String {
        let number = Double(self)
        if number >= 1000000 {
            return String(format: "%.1fM", number / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", number / 1000)
        } else {
            return "\(self)"
        }
    }
}

extension Double {
    var cleanValue: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

