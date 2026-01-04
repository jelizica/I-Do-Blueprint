//
//  VendorStatusCardV6.swift
//  I Do Blueprint
//
//  Native macOS "Wow Factor" version with premium visual design:
//  - SwiftUI Material backgrounds for vibrancy
//  - Gradient border strokes for depth
//  - Multi-layer macOS-native shadows
//  - Hover elevation with spring animations
//  - Staggered appearance animations
//  - System colors that adapt to light/dark mode
//  - Enhanced vendor rows with image loading
//

import SwiftUI

struct VendorStatusCardV6: View {
    @ObservedObject var store: VendorStoreV2
    @State private var selectedVendor: Vendor?
    
    // Animation state
    @State private var hasAppeared = false
    @State private var isHovered = false

    var body: some View {
        let totalVendors = store.vendors.count
        let bookedCount = store.vendors.filter { $0.isBooked == true }.count
        let pendingCount = totalVendors - bookedCount
        let bookingProgress = totalVendors > 0 ? Double(bookedCount) / Double(totalVendors) : 0
        
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // MARK: - Header Section
            HStack(spacing: Spacing.md) {
                // Native icon badge
                NativeIconBadge(
                    systemName: "briefcase.fill",
                    color: AppColors.Vendor.booked,
                    size: 44
                )
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Our Vendors")
                        .font(Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(nsColor: .labelColor))

                    Text("\(bookedCount) vendors booked")
                        .font(Typography.caption)
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                
                Spacer()
                
                // Booking progress badge
                if totalVendors > 0 {
                    VStack(spacing: Spacing.xxs) {
                        Text("\(Int(bookingProgress * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppColors.Vendor.booked,
                                        AppColors.Vendor.booked.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Booked")
                            .font(Typography.caption2)
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(AppColors.Vendor.booked.opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : -10)
            
            // Native gradient divider
            NativeDividerStyle(opacity: 0.4)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)
            
            // MARK: - Progress Bar Section
            if totalVendors > 0 {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.Vendor.booked, AppColors.Vendor.booked.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("Booking Progress")
                            .font(Typography.caption)
                            .foregroundColor(Color(nsColor: .labelColor))

                        Spacer()

                        HStack(spacing: Spacing.xs) {
                            Text("\(bookedCount)")
                                .font(Typography.caption.weight(.semibold))
                                .foregroundColor(SemanticColors.success)
                            
                            Text("/")
                                .font(Typography.caption)
                                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                            
                            Text("\(totalVendors)")
                                .font(Typography.caption.weight(.semibold))
                                .foregroundColor(Color(nsColor: .labelColor))
                        }
                    }

                    // Native progress bar with inner shadow and glow
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Track with inner shadow effect
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(nsColor: .separatorColor).opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                                )
                                .frame(height: 10)

                            // Progress fill with gradient and glow
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.Vendor.booked, AppColors.Vendor.booked.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geometry.size.width * bookingProgress, 10), height: 10)
                                .shadow(color: AppColors.Vendor.booked.opacity(0.4), radius: 4, x: 0, y: 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: bookingProgress)
                        }
                    }
                    .frame(height: 10)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)
                .padding(.bottom, Spacing.sm)
            }
            
            // MARK: - Vendor List Section
            if !store.vendors.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Section divider
                    NativeDividerStyle(opacity: 0.3)
                        .padding(.vertical, Spacing.sm)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)

                    // Section header
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.Vendor.booked)
                        
                        Text("Vendor List")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundColor(Color(nsColor: .labelColor))
                        
                        Spacer()
                        
                        if pendingCount > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(SemanticColors.warning)
                                    .frame(width: 6, height: 6)
                                
                                Text("\(pendingCount) pending")
                                    .font(Typography.caption2)
                                    .foregroundColor(SemanticColors.warning)
                            }
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)

                    // Vendor rows
                    ForEach(Array(store.vendors.prefix(7).enumerated()), id: \.element.id) { index, vendor in
                        NativeVendorRow(vendor: vendor)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedVendor = vendor
                            }
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.45 + Double(index) * 0.04), value: hasAppeared)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: Spacing.md) {
                    NativeDividerStyle(opacity: 0.3)
                        .padding(.vertical, Spacing.sm)
                    
                    VStack(spacing: Spacing.sm) {
                        // Info icon with gradient
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppColors.Vendor.booked.opacity(0.15),
                                            AppColors.Vendor.booked.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AppColors.Vendor.booked,
                                            AppColors.Vendor.booked.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .shadow(color: AppColors.Vendor.booked.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Text("No vendors added yet")
                            .font(Typography.caption)
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)
            }
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 467)
        // Native macOS card styling
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.4 : 0.3),
                            Color.white.opacity(isHovered ? 0.15 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        // Multi-layer macOS shadows
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 0.5)
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.05), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        .shadow(color: Color.black.opacity(isHovered ? 0.04 : 0.02), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
        // Hover interaction
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailModalV6(vendor: vendor, vendorStore: store)
        }
    }
}

// MARK: - Native Vendor Row Component

private struct NativeVendorRow: View {
    let vendor: Vendor
    @State private var loadedImage: NSImage?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Vendor icon/image with native styling
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [vendorColor.opacity(0.2), vendorColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                if let image = loadedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                } else {
                    Image(systemName: vendorIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [vendorColor, vendorColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(vendor.vendorName)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(Color(nsColor: .labelColor))
                    .lineLimit(1)

                Text(vendor.vendorType ?? "Vendor")
                    .font(Typography.caption2)
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .lineLimit(1)
            }

            Spacer()

            // Status badge
            HStack(spacing: 4) {
                if vendor.isBooked == true {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(SemanticColors.success)
                } else {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(SemanticColors.warning)
                }
                
                Text(vendor.isBooked == true ? "Booked" : "Pending")
                    .font(Typography.caption2.weight(.medium))
                    .foregroundColor(vendor.isBooked == true ? SemanticColors.success : SemanticColors.warning)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill((vendor.isBooked == true ? SemanticColors.success : SemanticColors.warning).opacity(0.1))
            )
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
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

    private var vendorIcon: String {
        guard let vendorType = vendor.vendorType?.lowercased() else {
            return "briefcase.fill"
        }

        if vendorType.contains("photo") {
            return "camera.fill"
        } else if vendorType.contains("cater") {
            return "fork.knife"
        } else if vendorType.contains("flower") {
            return "leaf.fill"
        } else if vendorType.contains("music") {
            return "music.note"
        } else {
            return "briefcase.fill"
        }
    }

    private var vendorColor: Color {
        guard let vendorType = vendor.vendorType?.lowercased() else {
            return ThemeAwareVendorTint.generic
        }

        if vendorType.contains("photo") {
            return ThemeAwareVendorTint.photography
        } else if vendorType.contains("cater") {
            return ThemeAwareVendorTint.catering
        } else if vendorType.contains("flower") {
            return ThemeAwareVendorTint.florals
        } else if vendorType.contains("music") {
            return ThemeAwareVendorTint.music
        } else {
            return ThemeAwareVendorTint.generic
        }
    }
}

// MARK: - Preview

#Preview("Vendor Status V6 - Light") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VendorStatusCardV6(
            store: VendorStoreV2()
        )
        .frame(width: 400, height: 550)
        .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Vendor Status V6 - Dark") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VendorStatusCardV6(
            store: VendorStoreV2()
        )
        .frame(width: 400, height: 550)
        .padding()
    }
    .preferredColorScheme(.dark)
}
