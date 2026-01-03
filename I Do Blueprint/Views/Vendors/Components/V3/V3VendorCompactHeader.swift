//
//  V3VendorCompactHeader.swift
//  I Do Blueprint
//
//  Compact header for vendor detail view (80pt height, horizontal layout)
//  Used when window height is below 550pt threshold
//

import SwiftUI

struct V3VendorCompactHeader: View {
    let vendor: Vendor
    let onClose: () -> Void
    
    @State private var loadedVendorImage: NSImage?
    
    private let logger = AppLogger.ui
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Vendor Logo (smaller, 50pt)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                vendor.statusColor.opacity(0.3),
                                vendor.statusColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(avatarContent)
                    .shadow(color: vendor.statusColor.opacity(0.2), radius: 8, y: 3)
            }
            
            // Vendor Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(vendor.vendorName)
                    .font(Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: Spacing.sm) {
                    if let vendorType = vendor.vendorType {
                        Text(vendorType)
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                    
                    // Status Badge (compact)
                    HStack(spacing: 4) {
                        Image(systemName: vendor.isBooked == true ? "checkmark.seal.fill" : "clock.badge.fill")
                            .font(.system(size: 10))
                        Text(vendor.statusDisplayName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(vendor.statusColor.opacity(0.15))
                    )
                    .foregroundColor(vendor.statusColor)
                }
            }
            
            Spacer()
            
            // Close Button
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SemanticColors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(height: 80)
        .background(
            LinearGradient(
                colors: [
                    vendor.statusColor.opacity(0.1),
                    SemanticColors.backgroundPrimary
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }
    
    // MARK: - Avatar Content
    
    @ViewBuilder
    private var avatarContent: some View {
        if let loadedImage = loadedVendorImage {
            Image(nsImage: loadedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        } else {
            Image(systemName: vendor.vendorTypeIcon)
                .font(.system(size: 22))
                .foregroundColor(vendor.statusColor)
        }
    }
    
    // MARK: - Image Loading
    
    private func loadVendorImage() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            await MainActor.run {
                loadedVendorImage = nil
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    loadedVendorImage = nsImage
                }
            }
        } catch {
            logger.error("Failed to load vendor image from URL: \(imageUrl)", error: error)
            await MainActor.run {
                loadedVendorImage = nil
            }
        }
    }
}

// MARK: - Preview

#Preview("Compact Header - Booked") {
    V3VendorCompactHeader(
        vendor: .makeTest(isBooked: true),
        onClose: { }
    )
}

#Preview("Compact Header - Available") {
    V3VendorCompactHeader(
        vendor: .makeTest(isBooked: false, dateBooked: nil),
        onClose: { }
    )
}
