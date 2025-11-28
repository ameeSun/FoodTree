//
//  DesignSystem.swift
//  TreeBites
//
//  Design tokens and system constants
//

import SwiftUI

// MARK: - Color Tokens
extension Color {
    // Background
    static let bgElev1 = Color(hex: "FAFAFC")
    static let bgElev2Card = Color(hex: "FFFFFF")
    
    // Brand
    static let brandPrimary = Color(hex: "2FB16A")
    static let brandPrimaryInk = Color(hex: "0E5A36")
    static let brandSecondary = Color(hex: "FF6A5C")
    
    // Ink
    static let inkPrimary = Color(hex: "0A0A0F")
    static let inkSecondary = Color(hex: "5E5E6A")
    static let inkMuted = Color(hex: "9191A1")
    
    // Stroke
    static let strokeSoft = Color(hex: "E9E9F2")
    
    // State
    static let stateSuccess = Color(hex: "22C55E")
    static let stateWarn = Color(hex: "F59E0B")
    static let stateError = Color(hex: "EF4444")
    
    // Map POI
    static let mapPoiAvailable = Color(hex: "2FB16A")
    static let mapPoiLow = Color(hex: "F59E0B")
    static let mapPoiOut = Color(hex: "9CA3AF")
    
    // Helper initializer
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography
struct FTTypography {
    static func display(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .semibold))
            .lineSpacing(6)
    }
    
    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold))
            .lineSpacing(6)
    }
    
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .regular))
            .lineSpacing(6)
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .lineSpacing(5)
    }
}

// MARK: - Spacing & Layout
struct FTLayout {
    static let cornerRadiusCard: CGFloat = 24
    static let cornerRadiusPill: CGFloat = 12
    static let cornerRadiusButton: CGFloat = 16
    
    static let paddingS: CGFloat = 8
    static let paddingM: CGFloat = 16
    static let paddingL: CGFloat = 24
    static let paddingXL: CGFloat = 32
    
    static let hitArea: CGFloat = 44
    
    static let shadowRadius: CGFloat = 12
    static let shadowOpacity: Double = 0.12
}

// MARK: - Animation Timings
struct FTAnimation {
    static let quick: Double = 0.18
    static let normal: Double = 0.24
    static let slow: Double = 0.36
    
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let easeInOut = Animation.easeInOut(duration: normal)
}

// MARK: - Haptics
struct FTHaptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Shadow Modifier
struct FTShadow: ViewModifier {
    var radius: CGFloat = FTLayout.shadowRadius
    var opacity: Double = FTLayout.shadowOpacity
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: 4)
    }
}

extension View {
    func ftShadow(radius: CGFloat = FTLayout.shadowRadius, opacity: Double = FTLayout.shadowOpacity) -> some View {
        modifier(FTShadow(radius: radius, opacity: opacity))
    }
    
    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Date Extensions
extension Date {
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

// MARK: - CLLocationCoordinate2D Extensions
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

