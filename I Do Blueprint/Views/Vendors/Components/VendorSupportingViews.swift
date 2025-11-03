//
//  VendorSupportingViews.swift
//  I Do Blueprint
//
//  Supporting view components for vendor detail views
//

import AppKit
import SwiftUI

// MARK: - Vendor Header

struct VendorHeaderView: View {
    let vendor: Vendor

    var body: some View {
        VStack(spacing: 20) {
            // Vendor image
            AsyncImage(url: URL(string: vendor.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.textSecondary.opacity(0.2), AppColors.textSecondary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5)))
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppColors.textPrimary.opacity(0.5), lineWidth: 2))

            VStack(spacing: 12) {
                Text(vendor.vendorName)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .multilineTextAlignment(.center)

                if let category = vendor.budgetCategoryName {
                    Text(category)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.12)))
                        .foregroundColor(.blue)
                }

                if let contact = vendor.contactName {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.secondary)
                        Text(contact)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4))
    }
}

// MARK: - Vendor Status View

struct VendorStatusView: View {
    let vendor: Vendor
    let vendorDetails: VendorDetails

    var body: some View {
        HStack(spacing: 12) {
            // Booking status
            StatusIndicator(
                title: "Status",
                value: vendor.isArchived ? "Archived" : ((vendor.isBooked == true) ? "Booked" : "Available"),
                color: vendor.isArchived ? AppColors.Vendor.notContacted : ((vendor.isBooked == true) ? AppColors.Vendor.booked : AppColors.Vendor.pending),
                icon: vendor
                    .isArchived ? "archivebox.fill" : ((vendor.isBooked == true) ? "checkmark.circle.fill" : "circle"))

            // Contract status
            if vendorDetails.contractStatus != .none {
                StatusIndicator(
                    title: "Contract",
                    value: vendorDetails.contractStatus.displayName,
                    color: vendorDetails.contractStatus.color,
                    icon: "doc.text.fill")
            }

            // Rating
            if let rating = vendorDetails.avgRating, rating > 0 {
                StatusIndicator(
                    title: "Rating",
                    value: String(format: "%.1f", rating),
                    color: .yellow,
                    icon: "star.fill")
            }
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4))
    }
}

struct StatusIndicator: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let title: String
    let value: String
    let isEditing: Bool
    @Binding var editValue: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)

            if isEditing {
                TextField(title, text: $editValue)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> URL?
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()

            if let url = action() {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(Spacing.sm)
                        .background(Circle().fill(Color.blue.opacity(0.12)))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.08 : 0.04), radius: isHovering ? 6 : 3, x: 0, y: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Financial Row

struct FinancialRow: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(color)
                    .font(.system(size: 24))
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.25), lineWidth: 1.5))
    }
}
