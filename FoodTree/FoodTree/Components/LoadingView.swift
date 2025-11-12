//
//  LoadingView.swift
//  FoodTree
//
//  Loading states and progress indicators
//

import SwiftUI

// MARK: - Spinning Leaf Loader
struct SpinningLeafLoader: View {
    @State private var isRotating = false
    let size: CGFloat
    
    init(size: CGFloat = 40) {
        self.size = size
    }
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size))
            .foregroundColor(.brandPrimary)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

// MARK: - Pull to Refresh Indicator
struct PullToRefreshIndicator: View {
    let progress: CGFloat // 0 to 1
    
    var body: some View {
        Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "arrow.down.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(.brandPrimary)
            .rotationEffect(.degrees(progress * 180))
            .scaleEffect(min(progress, 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: progress)
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                SpinningLeafLoader(size: 48)
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard)
                    .fill(Color.inkPrimary.opacity(0.9))
            )
        }
    }
}

