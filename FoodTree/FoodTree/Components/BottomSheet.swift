//
//  BottomSheet.swift
//  TreeBites
//
//  Physics-based bottom sheet with detents
//

import SwiftUI

struct BottomSheet<Content: View>: View {
    @Binding var detent: Detent
    let detents: [Detent]
    let content: Content
    
    @State private var dragOffset: CGFloat = 0
    @State private var previousDetent: Detent
    
    enum Detent: CGFloat, CaseIterable {
        case peek = 96
        case mid = 400
        case full = 0 // Will be calculated based on screen
        
        var height: CGFloat {
            if self == .full {
                return UIScreen.main.bounds.height - 100
            }
            return rawValue
        }
    }
    
    init(detent: Binding<Detent>, detents: [Detent] = Detent.allCases, @ViewBuilder content: () -> Content) {
        self._detent = detent
        self.detents = detents
        self.content = content()
        self._previousDetent = State(initialValue: detent.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.inkMuted.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // Content
            content
        }
        .frame(maxWidth: .infinity)
        .frame(height: detent.height + dragOffset)
        .background(
            Color.bgElev2Card
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .ignoresSafeArea()
        )
        .ftShadow(radius: 20, opacity: 0.15)
        .offset(y: UIScreen.main.bounds.height - detent.height - dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.height
                    dragOffset = -translation
                }
                .onEnded { value in
                    let velocity = value.predictedEndLocation.y - value.location.y
                    snapToNearestDetent(velocity: velocity)
                }
        )
        .animation(FTAnimation.spring, value: detent)
        .animation(FTAnimation.spring, value: dragOffset)
    }
    
    private func snapToNearestDetent(velocity: CGFloat) {
        let currentHeight = detent.height + dragOffset
        
        // Find nearest detent
        var nearestDetent = detents[0]
        var minDistance = abs(currentHeight - detents[0].height)
        
        for d in detents {
            let distance = abs(currentHeight - d.height)
            if distance < minDistance {
                minDistance = distance
                nearestDetent = d
            }
        }
        
        // Consider velocity for swipe gestures
        if abs(velocity) > 300 {
            if velocity < 0 { // Swiping up
                if let nextIndex = detents.firstIndex(of: nearestDetent), nextIndex < detents.count - 1 {
                    nearestDetent = detents[nextIndex + 1]
                }
            } else { // Swiping down
                if let prevIndex = detents.firstIndex(of: nearestDetent), prevIndex > 0 {
                    nearestDetent = detents[prevIndex - 1]
                }
            }
        }
        
        detent = nearestDetent
        dragOffset = 0
        
        if nearestDetent != previousDetent {
            FTHaptics.light()
            previousDetent = nearestDetent
        }
    }
}

// MARK: - Bottom Sheet Modifier
struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detent: BottomSheet<SheetContent>.Detent
    let sheetContent: SheetContent
    
    init(isPresented: Binding<Bool>, detent: BottomSheet<SheetContent>.Detent = .mid, @ViewBuilder content: () -> SheetContent) {
        self._isPresented = isPresented
        self.detent = detent
        self.sheetContent = content()
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(FTAnimation.easeInOut) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
                
                VStack {
                    Spacer()
                    sheetContent
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(FTAnimation.spring, value: isPresented)
    }
}

extension View {
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        detent: BottomSheet<Content>.Detent = .mid,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(BottomSheetModifier(isPresented: isPresented, detent: detent, content: content))
    }
}

