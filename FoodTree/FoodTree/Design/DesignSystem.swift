//
//  DesignSystem.swift
//  TreeBites
//
//  Design tokens and system constants
//

import SwiftUI
import UIKit

// MARK: - Color Tokens
extension Color {
    // Background
    static let bgElev1 = Color(lightHex: "FAFAFC", darkHex: "0F1115")
    static let bgElev2Card = Color(lightHex: "FFFFFF", darkHex: "16181D")

    // Brand
    static let brandPrimary = Color(lightHex: "2FB16A", darkHex: "2FB16A")
    static let brandPrimaryInk = Color(lightHex: "0E5A36", darkHex: "6BE39D")
    static let brandSecondary = Color(lightHex: "FF6A5C", darkHex: "FF8A7E")

    // Ink
    static let inkPrimary = Color(lightHex: "0A0A0F", darkHex: "F5F5F7")
    static let inkSecondary = Color(lightHex: "5E5E6A", darkHex: "B5B5C1")
    static let inkMuted = Color(lightHex: "9191A1", darkHex: "7E7E8A")

    // Stroke
    static let strokeSoft = Color(lightHex: "E9E9F2", darkHex: "2C2C34")

    // State
    static let stateSuccess = Color(lightHex: "22C55E", darkHex: "22C55E")
    static let stateWarn = Color(lightHex: "F59E0B", darkHex: "F5B947")
    static let stateError = Color(lightHex: "EF4444", darkHex: "F26666")
    
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

    init(lightHex: String, darkHex: String) {
        self = Color(UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? darkHex : lightHex)
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Typography
struct FTTypography {
    static func display(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .lineSpacing(6)
    }

    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .lineSpacing(6)
    }

    static func body(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .lineSpacing(6)
    }

    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular, design: .rounded))            .lineSpacing(5)
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

