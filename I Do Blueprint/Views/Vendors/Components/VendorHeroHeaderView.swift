//
//  VendorHeroHeaderView.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct VendorHeroHeaderView: View {
    let vendor: Vendor
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @State private var showingDeleteAlert = false

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
                // Avatar with decorative ring
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

                    // Avatar circle
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
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 42))
                                .foregroundColor(statusColor)
                        )
                        .shadow(color: statusColor.opacity(0.3), radius: 15, y: 5)
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
    }

    private var statusColor: Color {
        vendor.isBooked == true ? AppColors.Vendor.booked : AppColors.Vendor.pending
    }
}
