//
//  ConfettiView.swift
//  FoodTree
//
//  Playful confetti animation for success moments
//

import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    let leafColors: [Color] = [.brandPrimary, .stateSuccess, .brandSecondary, .stateWarn]
    
    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { index in
                ConfettiLeaf(color: leafColors[index % leafColors.count])
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: animate ? 800 : -100
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...720) : 0))
                    .opacity(animate ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: Double.random(in: 1.5...2.5))
                            .delay(Double.random(in: 0...0.3)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiLeaf: View {
    let color: Color
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: CGFloat.random(in: 12...24)))
            .foregroundColor(color)
    }
}

// MARK: - Success Celebration Modifier
struct SuccessCelebrationModifier: ViewModifier {
    @Binding var isShowing: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                ConfettiView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            isShowing = false
                        }
                    }
            }
        }
    }
}

extension View {
    func successCelebration(isShowing: Binding<Bool>) -> some View {
        modifier(SuccessCelebrationModifier(isShowing: isShowing))
    }
}

