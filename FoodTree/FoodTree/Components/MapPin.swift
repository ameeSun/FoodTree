//
//  MapPin.swift
//  FoodTree
//
//  Custom map annotation view with pulse animation
//

import SwiftUI
import MapKit

struct MapPinView: View {
    let post: FoodPost
    let isSelected: Bool
    
    @State private var isPulsing = false
    
    private var pinColor: Color {
        switch post.status {
        case .available:
            return .mapPoiAvailable
        case .low:
            return .mapPoiLow
        case .gone, .expired:
            return .mapPoiOut
        }
    }
    
    private var pinSize: CGFloat {
        // Size based on quantity
        if post.quantityApprox >= 50 {
            return isSelected ? 56 : 48
        } else if post.quantityApprox >= 20 {
            return isSelected ? 48 : 40
        } else {
            return isSelected ? 40 : 32
        }
    }
    
    var body: some View {
        ZStack {
            // Pulse ring (only for available items)
            if post.status == .available && !isSelected {
                Circle()
                    .stroke(pinColor.opacity(0.3), lineWidth: 2)
                    .frame(width: pinSize + 16, height: pinSize + 16)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 0.8)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            }
            
            // Main pin
            ZStack {
                // Background circle
                Circle()
                    .fill(pinColor)
                    .frame(width: pinSize, height: pinSize)
                
                // Icon or quantity
                if post.quantityApprox >= 10 {
                    Text("\(post.quantityApprox)")
                        .font(.system(size: pinSize / 2.5, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: pinSize / 2.5, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: pinSize + 6, height: pinSize + 6)
                }
            }
            .ftShadow(radius: isSelected ? 12 : 8, opacity: isSelected ? 0.25 : 0.18)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(FTAnimation.spring, value: isSelected)
        .onAppear {
            if post.status == .available {
                isPulsing = true
            }
        }
    }
}

// MARK: - User Location Pin
struct UserLocationPinView: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 2)
                .frame(width: 44, height: 44)
                .scaleEffect(isPulsing ? 1.4 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
                .animation(
                    Animation.easeOut(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: isPulsing
                )
            
            // Middle ring
            Circle()
                .stroke(Color.brandPrimary.opacity(0.4), lineWidth: 2)
                .frame(width: 32, height: 32)
            
            // Center dot
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 12, height: 12)
            }
            .ftShadow(radius: 8, opacity: 0.25)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Map Annotation (for MapKit integration)
struct FoodPostAnnotation: Identifiable {
    let id: String
    let post: FoodPost
    let coordinate: CLLocationCoordinate2D
    
    init(post: FoodPost) {
        self.id = post.id
        self.post = post
        self.coordinate = post.location.coordinate
    }
}

// MARK: - Unified Map Annotation
enum MapAnnotationItem: Identifiable {
    case foodPost(FoodPostAnnotation)
    case userLocation(UserLocationAnnotation)
    
    var id: String {
        switch self {
        case .foodPost(let annotation):
            return annotation.id
        case .userLocation(let annotation):
            return annotation.id
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .foodPost(let annotation):
            return annotation.coordinate
        case .userLocation(let annotation):
            return annotation.coordinate
        }
    }
}

// MARK: - User Location Annotation
struct UserLocationAnnotation: Identifiable {
    let id = "user-location"
    let coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

