//
//  FoodCard.swift
//  TreeBites
//
//  Reusable food card component with multiple sizes
//

import SwiftUI
import CoreLocation

struct FoodCard: View {
    let post: FoodPost
    let size: CardSize
    let userLocation: CLLocationCoordinate2D?
    let onTap: () -> Void
    
    enum CardSize {
        case small  // For horizontal scroll peek
        case medium // For feed list
        case large  // For detail preview
        
        var imageHeight: CGFloat {
            switch self {
            case .small: return 120
            case .medium: return 180
            case .large: return 240
            }
        }
        
        var width: CGFloat? {
            switch self {
            case .small: return 280
            case .medium, .large: return nil
            }
        }
    }
    
    init(post: FoodPost, size: CardSize = .medium, userLocation: CLLocationCoordinate2D? = nil, onTap: @escaping () -> Void = {}) {
        self.post = post
        self.size = size
        self.userLocation = userLocation
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            FTHaptics.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: size.imageHeight)
                        .overlay(
                            RemoteImage(
                                urlOrAsset: post.images.first ?? "placeholder",
                                contentMode: .fill
                            )
                            .frame(height: size.imageHeight)
                            .clipped()
                        )
                    
                    // Status pill overlay
                    StatusPill(status: post.status, animated: post.status == .available)
                        .padding(12)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(post.title)
                        .font(.system(size: size == .small ? 17 : 18, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                        .lineLimit(2)
                    
                    // Dietary tags
                    if !post.dietary.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(post.dietary.prefix(3)) { tag in
                                    DietaryChip(tag: tag, size: .small)
                                }
                                if post.dietary.count > 3 {
                                    Text("+\(post.dietary.count - 3)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.inkMuted)
                                }
                            }
                        }
                    }
                    
                    // Meta info
                    HStack(spacing: 8) {
                        // Quantity
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                            Text("~\(post.quantityApprox)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        
                        Text("•")
                            .foregroundColor(.inkMuted)
                        
                        // Time remaining
                        if let timeRemaining = post.timeRemaining {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 11))
                                Text("\(timeRemaining) min")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(timeRemaining < 15 ? .stateError : .inkSecondary)
                            
                            Text("•")
                                .foregroundColor(.inkMuted)
                        }
                        
                        // Distance
                        if let userLocation = userLocation {
                            let distance = post.location.distance(from: userLocation)
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 11))
                                Text(String(format: "%.1f mi", distance))
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                    }
                    .foregroundColor(.inkSecondary)
                    
                    // Organizer & building
                    HStack(spacing: 6) {
                        if post.organizer.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.brandPrimary)
                        }
                        
                        Text(post.organizer.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.inkSecondary)
                        
                        if let building = post.location.building {
                            Text("•")
                                .foregroundColor(.inkMuted)
                            Text(building)
                                .font(.system(size: 13))
                                .foregroundColor(.inkMuted)
                        }
                    }
                }
                .padding(FTLayout.paddingM)
            }
            .frame(width: size.width)
            .background(Color.bgElev2Card)
            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
            .ftShadow()
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    private var accessibilityDescription: String {
        var description = "\(post.title), \(post.status.displayName)"
        
        if let timeRemaining = post.timeRemaining {
            description += ", \(timeRemaining) minutes remaining"
        }
        
        if let userLocation = userLocation {
            let distance = post.location.distance(from: userLocation)
            description += String(format: ", %.1f miles away", distance)
        }
        
        description += ", \(post.quantityApprox) portions"
        
        if !post.dietary.isEmpty {
            description += ", dietary: \(post.dietary.map { $0.displayName }.joined(separator: ", "))"
        }
        
        return description
    }
}

// MARK: - Button Styles
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

