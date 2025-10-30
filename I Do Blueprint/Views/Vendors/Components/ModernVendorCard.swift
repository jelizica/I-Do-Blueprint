//
//  ModernVendorCard.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/9/25.
//  Modern vendor card component with enhanced design
//

import SwiftUI

struct ModernVendorCard: View {
    let vendor: Vendor
    let isSelected: Bool
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    @State private var loadedImage: NSImage?

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Avatar with logo or initials
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                statusColor.opacity(0.3),
                                statusColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                if let image = loadedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Text(vendor.initials)
                        .font(Typography.heading)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                }
            }

            // Vendor Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(vendor.vendorName)
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    // Status Badge
                    HStack(spacing: Spacing.xxs) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(vendor.statusDisplayName)
                    }
                    .badge(color: statusColor, size: .small)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Status: \(vendor.statusDisplayName)")

                    if let vendorType = vendor.vendorType {
                        Text(vendorType)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Metadata
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                if let quotedAmount = vendor.quotedAmount {
                    Text("$\(Int(quotedAmount))")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.info)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(AppColors.infoLight)
                        )
                }

                if let contactName = vendor.contactName {
                    Text(contactName)
                        .font(Typography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            // Selection Indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary.opacity(0.5))
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(isSelected ? AppColors.primaryLight : AppColors.cardBackground)
                .shadow(
                    color: isHovering ? AppColors.shadowMedium : AppColors.shadowLight,
                    radius: isHovering ? 6 : 3,
                    x: 0,
                    y: isHovering ? 3 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    isSelected ? AppColors.primary : (isHovering ? AppColors.borderHover : AppColors.borderLight),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(AnimationStyle.fast, value: isHovering)
        .animation(AnimationStyle.fast, value: isSelected)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        .contextMenu {
            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            if onDelete != nil {
                Divider()
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete Vendor", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete \(vendor.vendorName)? This action cannot be undone.")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vendor.vendorName), \(vendor.vendorType ?? "vendor")")
        .accessibilityHint("Double tap to view details")
        .accessibilityValue(accessibilityValueText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }

    private var statusColor: Color {
        vendor.isBooked == true ? AppColors.Vendor.booked : AppColors.Vendor.pending
    }

    private var accessibilityValueText: String {
        var parts: [String] = []
        parts.append(vendor.statusDisplayName)
        if let quotedAmount = vendor.quotedAmount {
            parts.append("$\(Int(quotedAmount))")
        }
        if let contactName = vendor.contactName {
            parts.append("Contact: \(contactName)")
        }
        return parts.joined(separator: ", ")
    }
    
    /// Load vendor image asynchronously from URL
    private func loadVendorImage() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            loadedImage = nil
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    loadedImage = nsImage
                }
            }
        } catch {
            await MainActor.run {
                loadedImage = nil
            }
        }
    }
}
