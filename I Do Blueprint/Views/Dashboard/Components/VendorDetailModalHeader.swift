//
//  VendorDetailModalHeader.swift
//  I Do Blueprint
//
//  Header component for vendor detail modal
//

import SwiftUI

struct VendorDetailModalHeader: View {
    let vendor: Vendor
    let loadedImage: NSImage?
    let onEdit: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Vendor Icon or Logo
            vendorIcon
            
            // Vendor Info
            vendorInfo
            
            Spacer()
            
            // Action Buttons
            actionButtons
        }
        .padding(Spacing.xl)
        .background(SemanticColors.textPrimary)
    }
    
    // MARK: - Components
    
    private var vendorIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientForVendorType(vendor.vendorType ?? ""),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            
            if let image = loadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Image(systemName: iconForVendorType(vendor.vendorType ?? ""))
                    .font(.system(size: 24))
                    .foregroundColor(SemanticColors.textPrimary)
            }
        }
    }
    
    private var vendorInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(vendor.vendorName)
                .font(Typography.title2)
                .foregroundColor(SemanticColors.textPrimary)
            
            HStack(spacing: Spacing.sm) {
                if let type = vendor.vendorType {
                    Text(type)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                
                if vendor.isBooked == true {
                    Text("•")
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Booked")
                            .font(Typography.caption2)
                    }
                    .foregroundColor(AppColors.Vendor.booked)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.primaryAction)
                    .frame(width: 32, height: 32)
                    .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
                    .cornerRadius(CornerRadius.sm)
            }
            .buttonStyle(.plain)
            .accessibleActionButton(label: "Edit vendor", hint: "Opens edit form")
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(SemanticColors.backgroundSecondary)
                    .cornerRadius(CornerRadius.sm)
            }
            .buttonStyle(.plain)
            .accessibleActionButton(label: "Close modal", hint: "Closes vendor details")
        }
    }
    
    // MARK: - Helper Functions
    
    private func iconForVendorType(_ type: String) -> String {
        switch type.lowercased() {
        case "venue": return "mappin.circle.fill"
        case "photography", "photographer": return "camera.fill"
        case "catering", "caterer": return "fork.knife"
        case "music", "dj", "band": return "music.note"
        case "florist", "flowers": return "leaf.fill"
        default: return "briefcase.fill"
        }
    }
    
    private func gradientForVendorType(_ type: String) -> [Color] {
        switch type.lowercased() {
        case "venue": return [Color.fromHex("EC4899"), Color.fromHex("F43F5E")]
        case "photography", "photographer": return [Color.fromHex("A855F7"), Color.fromHex("EC4899")]
        case "catering", "caterer": return [Color.fromHex("F97316"), Color.fromHex("EC4899")]
        case "music", "dj", "band": return [Color.fromHex("3B82F6"), Color.fromHex("A855F7")]
        case "florist", "flowers": return [Color.fromHex("10B981"), Color.fromHex("059669")]
        default: return [Color.fromHex("6366F1"), Color.fromHex("8B5CF6")]
        }
    }
}
