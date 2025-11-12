//
//  QuantityDial.swift
//  FoodTree
//
//  Interactive circular quantity indicator
//

import SwiftUI

struct QuantityDial: View {
    let quantity: Int // 0-100
    let size: CGFloat
    let interactive: Bool
    @Binding var adjustedQuantity: Int?
    
    init(quantity: Int, size: CGFloat = 120, interactive: Bool = false, adjustedQuantity: Binding<Int?> = .constant(nil)) {
        self.quantity = quantity
        self.size = size
        self.interactive = interactive
        self._adjustedQuantity = adjustedQuantity
    }
    
    @State private var dragOffset: CGFloat = 0
    
    private var displayQuantity: Int {
        adjustedQuantity ?? quantity
    }
    
    private var progress: Double {
        Double(displayQuantity) / 100.0
    }
    
    private var ringColor: Color {
        if displayQuantity >= 50 {
            return .mapPoiAvailable
        } else if displayQuantity >= 20 {
            return .mapPoiLow
        } else {
            return .mapPoiOut
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.strokeSoft, lineWidth: size / 12)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: size / 12,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(FTAnimation.spring, value: progress)
            
            // Center content
            VStack(spacing: 4) {
                Text("\(displayQuantity)")
                    .font(.system(size: size / 3, weight: .bold))
                    .foregroundColor(.inkPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: displayQuantity)
                
                Text("portions")
                    .font(.system(size: size / 10, weight: .medium))
                    .foregroundColor(.inkSecondary)
            }
        }
        .frame(width: size, height: size)
        .gesture(
            interactive ? DragGesture()
                .onChanged { value in
                    let angle = atan2(value.location.y - size/2, value.location.x - size/2)
                    let percent = (angle + .pi/2) / (2 * .pi)
                    let newQuantity = Int(max(0, min(100, percent * 100)))
                    adjustedQuantity = newQuantity
                    FTHaptics.light()
                }
                : nil
        )
        .accessibilityLabel("Quantity: \(displayQuantity) portions")
        .accessibilityValue(interactive ? "Adjustable" : "")
    }
}

// MARK: - Slider-based Quantity Picker (for compose flow)
struct QuantitySlider: View {
    @Binding var quantity: Int
    let range: ClosedRange<Int>
    
    init(quantity: Binding<Int>, range: ClosedRange<Int> = 1...100) {
        self._quantity = quantity
        self.range = range
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Approximate portions")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.inkSecondary)
                
                Spacer()
                
                Text("\(quantity)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.brandPrimary)
                    .contentTransition(.numericText())
            }
            
            Slider(
                value: Binding(
                    get: { Double(quantity) },
                    set: { quantity = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(.brandPrimary)
            .onChange(of: quantity) { _ in
                FTHaptics.light()
            }
            
            HStack {
                Text("\(range.lowerBound)")
                    .font(.system(size: 12))
                    .foregroundColor(.inkMuted)
                Spacer()
                Text("\(range.upperBound)")
                    .font(.system(size: 12))
                    .foregroundColor(.inkMuted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quantity slider")
        .accessibilityValue("\(quantity) portions")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if quantity < range.upperBound {
                    quantity += 1
                }
            case .decrement:
                if quantity > range.lowerBound {
                    quantity -= 1
                }
            @unknown default:
                break
            }
        }
    }
}

