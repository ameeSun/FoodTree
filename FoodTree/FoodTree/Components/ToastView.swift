//
//  ToastView.swift
//  FoodTree
//
//  Non-blocking toast notifications
//

import SwiftUI

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: Double
    
    enum ToastType {
        case success
        case error
        case info
        case warning
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .stateSuccess
            case .error: return .stateError
            case .info: return .brandPrimary
            case .warning: return .stateWarn
            }
        }
    }
    
    init(message: String, type: ToastType = .info, duration: Double = 3.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

struct ToastView: View {
    let toast: Toast
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20))
                .foregroundColor(toast.type.color)
            
            Text(toast.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.inkPrimary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(FTLayout.paddingM)
        .background(
            RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill)
                .fill(Color.bgElev2Card)
                .ftShadow(radius: 16, opacity: 0.2)
        )
        .padding(.horizontal, FTLayout.paddingM)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let toast = toast {
                ToastView(toast: toast)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                            withAnimation(FTAnimation.easeInOut) {
                                self.toast = nil
                            }
                        }
                    }
            }
        }
        .animation(FTAnimation.spring, value: toast?.id)
    }
}

extension View {
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

