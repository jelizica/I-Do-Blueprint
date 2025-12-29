//
//  VendorStatusCardV4.swift
//  I Do Blueprint
//
//  Vendor status card for dashboard - displays vendor list with booking status
//

import SwiftUI

struct VendorStatusCardV4: View {
    @ObservedObject var store: VendorStoreV2
    @State private var selectedVendor: Vendor?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Our Vendors")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)

                Text("\(bookedCount) vendors booked")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.bottom, Spacing.sm)

            Divider()

            // Vendor List
            VStack(spacing: Spacing.md) {
                ForEach(store.vendors.prefix(7)) { vendor in
                    VendorRow(vendor: vendor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedVendor = vendor
                        }
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 467)
        .background(AppColors.cardBackground)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailModal(vendor: vendor, vendorStore: store)
        }
    }

    private var bookedCount: Int {
        store.vendors.filter { $0.isBooked == true }.count
    }
}
