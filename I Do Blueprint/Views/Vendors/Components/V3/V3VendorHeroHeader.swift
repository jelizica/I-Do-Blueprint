//
//  V3VendorHeroHeader.swift
//  I Do Blueprint
//
//  Hero header component for V3 vendor detail view
//  Displays vendor logo, name, status, and action buttons
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct V3VendorHeroHeader: View {
    let vendor: Vendor
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void
    let onLogoUpdated: (NSImage?) async -> Void

    @State private var showingDeleteAlert = false
    @State private var showingPhotosPicker = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var loadedVendorImage: NSImage?
    @State private var isHoveringLogo = false
    @State private var isUploadingLogo = false

    private let logger = AppLogger.ui

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            backgroundGradient

            // Decorative pattern overlay
            decorativePattern

            // Profile content
            profileContent
        }
        .overlay(alignment: .topLeading) {
            closeButton
        }
        .overlay(alignment: .topTrailing) {
            actionButtons
        }
        .alert("Delete Vendor", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \(vendor.vendorName)? This action cannot be undone.")
        }
        .photosPicker(
            isPresented: $showingPhotosPicker,
            selection: $photosPickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                await handlePhotosPickerSelection(newItem)
            }
        }
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                vendor.statusColor.opacity(0.3),
                vendor.statusColor.opacity(0.1),
                AppColors.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 280)
    }

    private var decorativePattern: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height: CGFloat = 280

                // Diagonal lines pattern
                for i in stride(from: -100, to: Int(width) + 100, by: 30) {
                    path.move(to: CGPoint(x: CGFloat(i), y: 0))
                    path.addLine(to: CGPoint(x: CGFloat(i) + 100, y: height))
                }
            }
            .stroke(vendor.statusColor.opacity(0.05), lineWidth: 1)
        }
        .frame(height: 280)
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        VStack(spacing: Spacing.lg) {
            // Avatar with logo upload
            avatarSection

            // Name and status
            VStack(spacing: Spacing.sm) {
                Text(vendor.vendorName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                statusBadge
            }
        }
        .padding(.bottom, Spacing.xxl)
    }

    private var avatarSection: some View {
        ZStack {
            // Outer decorative ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            vendor.statusColor.opacity(0.5),
                            vendor.statusColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 128, height: 128)

            // Avatar circle with logo or default icon
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
                .frame(width: 120, height: 120)
                .overlay(avatarContent)
                .shadow(color: vendor.statusColor.opacity(0.3), radius: 15, y: 5)

            // Hover overlay with upload/remove options
            if isHoveringLogo {
                hoverOverlay
            }

            // Loading indicator
            if isUploadingLogo {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 120, height: 120)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHoveringLogo = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vendor logo")
        .accessibilityHint("Hover to change or remove logo")
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let loadedImage = loadedVendorImage {
            Image(nsImage: loadedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipShape(Circle())
        } else {
            Image(systemName: vendor.vendorTypeIcon)
                .font(.system(size: 42))
                .foregroundColor(vendor.statusColor)
        }
    }

    private var hoverOverlay: some View {
        Circle()
            .fill(AppColors.textPrimary.opacity(0.6))
            .frame(width: 120, height: 120)
            .overlay(
                VStack(spacing: Spacing.sm) {
                    Button {
                        showingPhotosPicker = true
                    } label: {
                        VStack(spacing: 4) {
                            let hasImage = loadedVendorImage != nil || vendor.imageUrl != nil
                            Image(systemName: hasImage ? "photo.badge.arrow.down" : "photo.badge.plus")
                                .font(.system(size: 20))
                            Text(hasImage ? "Change" : "Upload")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    if loadedVendorImage != nil || vendor.imageUrl != nil {
                        Button {
                            Task {
                                isUploadingLogo = true
                                await onLogoUpdated(nil)
                                loadedVendorImage = nil
                                photosPickerItem = nil
                                isUploadingLogo = false
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                Text("Remove")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            )
    }

    private var statusBadge: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: vendor.isBooked == true ? "checkmark.seal.fill" : "clock.badge.fill")
                .font(.caption)
            Text(vendor.statusDisplayName)
                .font(Typography.subheading)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(vendor.statusColor.opacity(0.15))
        )
        .foregroundColor(vendor.statusColor)
        .accessibilityLabel("Status: \(vendor.statusDisplayName)")
    }

    // MARK: - Action Buttons

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(AppColors.textSecondary.opacity(0.8))
                        .frame(width: 36, height: 36)
                )
        }
        .buttonStyle(.plain)
        .padding()
        .accessibilityLabel("Close")
        .accessibilityHint("Closes vendor details")
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 36, height: 36)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete vendor")
            .accessibilityHint("Shows delete confirmation")

            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 36, height: 36)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit vendor")
            .accessibilityHint("Opens edit form")
        }
        .padding()
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

    /// Handle image selection from PhotosPicker
    private func handlePhotosPickerSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        await MainActor.run {
            isUploadingLogo = true
        }
        
        do {
            // Load the image data from PhotosPicker
            if let data = try await item.loadTransferable(type: Data.self) {
                if let nsImage = NSImage(data: data) {
                    await onLogoUpdated(nsImage)
                    await MainActor.run {
                        loadedVendorImage = nsImage
                        isUploadingLogo = false
                    }
                    logger.info("Logo selected from Photos library for vendor: \(vendor.vendorName)")
                } else {
                    logger.error("Failed to create NSImage from photo data")
                    await MainActor.run {
                        isUploadingLogo = false
                    }
                }
            } else {
                logger.error("Failed to load transferable data from PhotosPicker")
                await MainActor.run {
                    isUploadingLogo = false
                }
            }
        } catch {
            logger.error("Error loading photo from picker", error: error)
            await MainActor.run {
                isUploadingLogo = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Hero Header - Booked") {
    V3VendorHeroHeader(
        vendor: .makeTest(isBooked: true),
        onEdit: { },
        onDelete: { },
        onClose: { },
        onLogoUpdated: { _ in }
    )
    .frame(height: 280)
}

#Preview("Hero Header - Available") {
    V3VendorHeroHeader(
        vendor: .makeTest(isBooked: false, dateBooked: nil),
        onEdit: { },
        onDelete: { },
        onClose: { },
        onLogoUpdated: { _ in }
    )
    .frame(height: 280)
}
