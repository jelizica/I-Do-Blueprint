//
//  VendorHeroHeaderView.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI
import UniformTypeIdentifiers

struct VendorHeroHeaderView: View {
    let vendor: Vendor
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    var onLogoUpdated: ((NSImage?) -> Void)? = nil
    @State private var showingDeleteAlert = false
    @State private var showingImagePicker = false
    @State private var selectedLogoImage: NSImage?
    @State private var loadedVendorImage: NSImage?
    @State private var isHoveringLogo = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [
                    statusColor.opacity(0.3),
                    statusColor.opacity(0.1),
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)

            // Decorative pattern overlay
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
                .stroke(statusColor.opacity(0.05), lineWidth: 1)
            }
            .frame(height: 280)

            // Profile content
            VStack(spacing: Spacing.lg) {
                // Avatar with decorative ring and logo upload
                ZStack {
                    // Outer decorative ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    statusColor.opacity(0.5),
                                    statusColor.opacity(0.2)
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
                                    statusColor.opacity(0.3),
                                    statusColor.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Group {
                                if let logoImage = selectedLogoImage {
                                    // Display uploaded logo
                                    Image(nsImage: logoImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else if let loadedImage = loadedVendorImage {
                                    // Display existing logo from URL
                                    Image(nsImage: loadedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    // Default building icon
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 42))
                                        .foregroundColor(statusColor)
                                }
                            }
                        )
                        .shadow(color: statusColor.opacity(0.3), radius: 15, y: 5)
                    
                    // Hover overlay with upload/remove options
                    if isHoveringLogo {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 120, height: 120)
                            .overlay(
                                VStack(spacing: Spacing.sm) {
                                    Button(action: {
                                        showingImagePicker = true
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: selectedLogoImage != nil || vendor.imageUrl != nil ? "photo.badge.arrow.down" : "photo.badge.plus")
                                                .font(.system(size: 20))
                                            Text(selectedLogoImage != nil || vendor.imageUrl != nil ? "Change" : "Upload")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if selectedLogoImage != nil || vendor.imageUrl != nil {
                                        Button(action: {
                                            selectedLogoImage = nil
                                            onLogoUpdated?(nil)
                                        }) {
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
                }
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringLogo = hovering
                    }
                }

                // Name and status
                VStack(spacing: Spacing.sm) {
                    Text(vendor.vendorName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

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
                            .fill(statusColor.opacity(0.15))
                    )
                    .foregroundColor(statusColor)
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .overlay(alignment: .topLeading) {
            // Close button on the left
            if let onClose = onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.8))
                                .frame(width: 36, height: 36)
                        )
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: Spacing.sm) {
                if onDelete != nil {
                    Button(action: { showingDeleteAlert = true }) {
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
                }
                
                if let onEdit = onEdit {
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
                }
            }
            .padding()
        }
        .alert("Delete Vendor", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Are you sure you want to delete \(vendor.vendorName)? This action cannot be undone.")
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result)
        }
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }

    private var statusColor: Color {
        vendor.isBooked == true ? AppColors.Vendor.booked : AppColors.Vendor.pending
    }
    
    // MARK: - Private Methods
    
    /// Load vendor image asynchronously from URL
    private func loadVendorImage() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            loadedVendorImage = nil
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
            AppLogger.ui.error("Failed to load vendor image from URL: \(imageUrl)", error: error)
            await MainActor.run {
                loadedVendorImage = nil
            }
        }
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Load the image
            if let imageData = try? Data(contentsOf: url),
               let nsImage = NSImage(data: imageData) {
                selectedLogoImage = nsImage
                onLogoUpdated?(nsImage)
                AppLogger.ui.info("Logo selected for vendor: \(vendor.vendorName)")
            } else {
                AppLogger.ui.error("Failed to load image from URL: \(url.path)")
            }
            
        case .failure(let error):
            AppLogger.ui.error("Error selecting logo image", error: error)
        }
    }
}
