//
//  RemoteImage.swift
//  FoodTree
//
//  Reusable image component that handles both remote URLs and local asset names
//

import SwiftUI

struct RemoteImage: View {
    let urlOrAsset: String
    var placeholder: String = "placeholder"
    var contentMode: ContentMode = .fill
    
    private var isURL: Bool {
        urlOrAsset.hasPrefix("http://") || urlOrAsset.hasPrefix("https://")
    }
    
    var body: some View {
        Group {
            if isURL {
                // Remote URL - use AsyncImage
                AsyncImage(url: URL(string: urlOrAsset)) { phase in
                    switch phase {
                    case .empty:
                        // Loading state
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    case .success(let image):
                        // Successfully loaded
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        // Error loading - show gray placeholder instead of missing asset
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                            )
                    @unknown default:
                        // Fallback for unknown states
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                            )
                    }
                }
            } else {
                // Local asset name - try to load, fallback to system image if missing
                if let _ = UIImage(named: urlOrAsset) {
                    Image(urlOrAsset)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    // Asset not found - use system image
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
            }
        }
    }
}

// MARK: - Preview Helper
struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Local asset
            RemoteImage(urlOrAsset: "placeholder")
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Remote URL (will show loading/error in preview)
            RemoteImage(urlOrAsset: "https://example.com/image.jpg")
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}

