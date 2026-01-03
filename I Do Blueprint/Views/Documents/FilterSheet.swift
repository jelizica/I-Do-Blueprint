//
//  FilterSheet.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct FilterSheet: View {
    @ObservedObject var viewModel: DocumentStoreV2
    @Environment(\.dismiss) private var dismiss

    @State private var tempFilters: DocumentFilters
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var showCustomDatePicker = false

    init(viewModel: DocumentStoreV2) {
        self.viewModel = viewModel
        _tempFilters = State(initialValue: viewModel.filters)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Bucket filter
                Section("Storage Location") {
                    Picker("Bucket", selection: $tempFilters.selectedBucket) {
                        Text("All Buckets").tag(DocumentBucket?.none)

                        ForEach(DocumentBucket.allCases, id: \.self) { bucket in
                            HStack {
                                Image(systemName: bucket.iconName)
                                Text(bucket.displayName)
                            }
                            .tag(DocumentBucket?.some(bucket))
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                // Date range filter
                Section("Date Range") {
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            tempFilters.dateRange = nil
                        }) {
                            HStack {
                                if tempFilters.dateRange == nil {
                                    Image(systemName: "circle.fill")
                                        .font(.caption)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.caption)
                                }
                                Text("Any Time")
                            }
                        }
                        .buttonStyle(.plain)

                        ForEach(
                            [DocumentDateRange.last7Days, .last30Days, .last90Days, .thisYear],
                            id: \.self) { range in
                            Button(action: {
                                tempFilters.dateRange = range
                            }) {
                                HStack {
                                    if tempFilters.dateRange == range {
                                        Image(systemName: "circle.fill")
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.caption)
                                    }
                                    Text(range.displayName)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            showCustomDatePicker = true
                        }) {
                            HStack {
                                if case .custom = tempFilters.dateRange {
                                    Image(systemName: "circle.fill")
                                        .font(.caption)
                                    Text(tempFilters.dateRange!.displayName)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.caption)
                                    Text("Custom Range...")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Vendor filter
                Section("Vendor") {
                    Picker("Vendor", selection: $tempFilters.vendorId) {
                        Text("All Vendors").tag(Int?.none)

                        ForEach(viewModel.availableVendors, id: \.id) { vendor in
                            Text(vendor.name).tag(Int?.some(vendor.id))
                        }
                    }
                }

                // Tag filter
                Section("Tags") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Common tags from existing documents
                        if !commonTags.isEmpty {
                            Text("Common Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(commonTags.prefix(10), id: \.self) { tag in
                                        Button(action: {
                                            toggleTag(tag)
                                        }) {
                                            HStack(spacing: 4) {
                                                Text(tag)
                                                    .font(.caption)

                                                if tempFilters.tags.contains(tag) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.caption)
                                                }
                                            }
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, Spacing.xs)
                                            .background(
                                                Capsule()
                                                    .fill(tempFilters.tags.contains(tag) ? Color.blue
                                                        .opacity(0.2) : SemanticColors.textSecondary.opacity(Opacity.subtle)))
                                            .foregroundColor(tempFilters.tags.contains(tag) ? .blue : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Selected tags
                        if !tempFilters.tags.isEmpty {
                            Text("Active Tags")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tempFilters.tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .font(.caption)

                                            Button(action: {
                                                tempFilters.tags.removeAll { $0 == tag }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, Spacing.xs)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.2)))
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }

                // Sort options
                Section("Sort By") {
                    Picker("Sort", selection: $viewModel.sortOption) {
                        ForEach(DocumentSortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                // Active filters summary
                if tempFilters.hasActiveFilters {
                    Section {
                        Button("Clear All Filters") {
                            tempFilters.clear()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCustomDatePicker) {
                CustomDateRangePicker(
                    startDate: $customStartDate,
                    endDate: $customEndDate,
                    onApply: {
                        tempFilters.dateRange = .custom(start: customStartDate, end: customEndDate)
                        showCustomDatePicker = false
                    },
                    onCancel: {
                        showCustomDatePicker = false
                    })
            }
        }
        .frame(width: 500, height: 700)
    }

    // MARK: - Helper Properties

    private var commonTags: [String] {
        // Extract all unique tags from documents
        let allTags = viewModel.documents.flatMap(\.tags)
        let uniqueTags = Array(Set(allTags)).sorted()
        return uniqueTags
    }

    // MARK: - Helper Methods

    private func toggleTag(_ tag: String) {
        if tempFilters.tags.contains(tag) {
            tempFilters.tags.removeAll { $0 == tag }
        } else {
            tempFilters.tags.append(tag)
        }
    }

    private func applyFilters() {
        viewModel.filters = tempFilters
        viewModel.applyFilters()
    }
}

// MARK: - Custom Date Range Picker

struct CustomDateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            .formStyle(.grouped)
            .navigationTitle("Custom Date Range")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                    }
                    .disabled(startDate > endDate)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

// MARK: - Preview

#Preview {
    FilterSheet(viewModel: DocumentStoreV2())
}
