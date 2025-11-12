//
//  DietaryChip.swift
//  FoodTree
//
//  Dietary tag chips with icons
//

import SwiftUI

struct DietaryChip: View {
    let tag: DietaryTag
    let size: ChipSize
    
    enum ChipSize {
        case small, medium
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 13
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            }
        }
    }
    
    init(tag: DietaryTag, size: ChipSize = .medium) {
        self.tag = tag
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tag.icon)
                .font(.system(size: size.iconSize, weight: .semibold))
            
            Text(tag.displayName)
                .font(.system(size: size.fontSize, weight: .medium))
        }
        .foregroundColor(chipColor)
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding - 2)
        .background(chipBackgroundColor)
        .clipShape(Capsule())
        .accessibilityLabel(tag.displayName)
    }
    
    private var chipColor: Color {
        switch tag {
        case .containsNuts:
            return .stateError
        default:
            return .brandPrimaryInk
        }
    }
    
    private var chipBackgroundColor: Color {
        switch tag {
        case .containsNuts:
            return Color.stateError.opacity(0.1)
        default:
            return Color.brandPrimary.opacity(0.1)
        }
    }
}

// MARK: - Dietary Filter Chip (selectable)
struct DietaryFilterChip: View {
    let tag: DietaryTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            FTHaptics.light()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: tag.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(tag.displayName)
                    .font(.system(size: 15, weight: .medium))
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                }
            }
            .foregroundColor(isSelected ? .white : .brandPrimaryInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.brandPrimary : Color.bgElev2Card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.strokeSoft, lineWidth: 1)
            )
            .ftShadow(radius: isSelected ? 8 : 4, opacity: isSelected ? 0.2 : 0.08)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(tag.displayName), \(isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

