//
//  StatusPill.swift
//  FoodTree
//
//  Status indicator pills (Available, Low, Gone, Expired)
//

import SwiftUI

struct StatusPill: View {
    let status: FoodPost.PostStatus
    let animated: Bool
    
    init(status: FoodPost.PostStatus, animated: Bool = false) {
        self.status = status
        self.animated = animated
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if animated && status == .available {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                    .modifier(PulseModifier())
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
            }
            
            Text(status.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(status.displayName)")
    }
    
    private var statusColor: Color {
        switch status {
        case .available:
            return .mapPoiAvailable
        case .low:
            return .mapPoiLow
        case .gone, .expired:
            return .mapPoiOut
        }
    }
}

// MARK: - Perishability Badge
struct PerishabilityBadge: View {
    let perishability: FoodPost.Perishability
    let showAnimation: Bool
    
    init(perishability: FoodPost.Perishability, showAnimation: Bool = false) {
        self.perishability = perishability
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "drop.fill")
                .font(.system(size: 11))
                .if(showAnimation && perishability == .high) { view in
                    view.modifier(PerishabilityPulseModifier())
                }
            
            Text(perishability.displayName)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(perishabilityColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(perishabilityColor.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("Perishability: \(perishability.displayName)")
    }
    
    private var perishabilityColor: Color {
        switch perishability {
        case .low:
            return .stateSuccess
        case .medium:
            return .stateWarn
        case .high:
            return .stateError
        }
    }
}

// MARK: - Pulse Animation
struct PulseModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.4 : 1.0)
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct PerishabilityPulseModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.15 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// Helper for conditional modifiers
struct AnyViewModifier: ViewModifier {
    let modifier: any ViewModifier
    
    init(_ modifier: any ViewModifier) {
        self.modifier = modifier
    }
    
    func body(content: Content) -> some View {
        content
    }
}

struct EmptyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

