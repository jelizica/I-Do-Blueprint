//
//  VendorCardV3.swift
//  I Do Blueprint
//
//  Individual vendor card component
//

import SwiftUI

struct VendorCardV3: View {
    let vendor: Vendor
    @State private var loadedImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Avatar and Status Badge
            ZStack(alignment: .topTrailing) {
                avatarSection
                statusBadge
                    .padding(.top, Spacing.xxl)
                    .padding(.trailing, Spacing.xxl)
            }
            .frame(height: 72)

            // Vendor Name
            Text(vendor.vendorName)
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.sm)

            // Contact Email
            if let email = vendor.email, !email.isEmpty {
                Text(email)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.xs)
            }

            // Vendor Type
            if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                Text(vendorType)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.sm)
            }

            Spacer()

            // Quoted Amount Section
            quotedAmountSection
        }
        .frame(minWidth: 250, maxWidth: .infinity) // Flexible width (matches GuestCardV4)
        .frame(height: 243)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SemanticColors.borderLight, lineWidth: 0.5)
        )
        .accessibleListItem(
            label: vendor.vendorName,
            hint: "Tap to view vendor details",
            value: vendor.isBooked == true ? "Booked" : "Available"
        )
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        Circle()
            .fill(SemanticColors.backgroundSecondary)
            .frame(width: 48, height: 48)
            .overlay(
                Group {
                    if let image = loadedImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.xxl)
            .padding(.leading, Spacing.xxl)
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        Group {
            if vendor.isArchived {
                Text("Archived")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.statusWarning)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.statusWarning.opacity(Opacity.light))
                    .cornerRadius(9999)
            } else if vendor.isBooked == true {
                Text("Booked")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.statusSuccess)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.statusSuccess.opacity(Opacity.light))
                    .cornerRadius(9999)
            } else {
                Text("Available")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.statusPending)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.statusPending.opacity(Opacity.light))
                    .cornerRadius(9999)
            }
        }
    }
    
    // MARK: - Quoted Amount Section
    
    private var quotedAmountSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(SemanticColors.borderLight)

            HStack {
                Text("Quoted Amount")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text(formatCurrency(vendor.quotedAmount ?? 0))
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.md)
        }
    }
    
    // MARK: - Helper Methods
    
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
