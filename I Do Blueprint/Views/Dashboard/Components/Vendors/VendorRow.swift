//
//  VendorRow.swift
//  I Do Blueprint
//
//  Individual vendor row for dashboard vendor card
//

import SwiftUI

struct VendorRow: View {
    let vendor: Vendor
    @State private var loadedImage: NSImage?

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(vendorColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Group {
                        if let image = loadedImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: vendorIcon)
                                .foregroundColor(vendorColor)
                        }
                    }
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(vendor.vendorName)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(vendor.vendorType ?? "Vendor")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(vendor.isBooked == true ? "✓ Booked" : "Pending")
                .font(Typography.caption)
                .foregroundColor(vendor.isBooked == true ? AppColors.success : AppColors.warning)
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
            return AppColors.Vendor.TypeTint.generic
        }

        if vendorType.contains("photo") {
            return AppColors.Vendor.TypeTint.photography
        } else if vendorType.contains("cater") {
            return AppColors.Vendor.TypeTint.catering
        } else if vendorType.contains("flower") {
            return AppColors.Vendor.TypeTint.florals
        } else if vendorType.contains("music") {
            return AppColors.Vendor.TypeTint.music
        } else {
            return AppColors.Vendor.TypeTint.generic
        }
    }
}
