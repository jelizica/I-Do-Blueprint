//
//  SearchFiltersView.swift
//  I Do Blueprint
//
//  Advanced search filters for visual planning content
//

import SwiftUI

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    let onApply: () -> Void
    let onDismiss: () -> Void

    @State private var localFilters: SearchFilters
    @State private var selectedDateRangeOption: DateRangeOption = .allTime
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var showingColorPicker = false
    @State private var newColorToAdd: Color = .blue

    private let logger = AppLogger.ui

    init(filters: Binding<SearchFilters>, onApply: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self.onDismiss = onDismiss
        self._localFilters = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Filters
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    typeFiltersSection
                    dateRangeSection
                    styleFiltersSection
                    colorFiltersSection
                    additionalOptionsSection
                }
                .padding()
            }

            Divider()

            // Footer
            footerSection
        }
        .frame(width: 450, height: 650)
        .onAppear {
            initializeDateRange()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Search Filters")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close filters")
        }
        .padding()
    }

    // MARK: - Type Filters

    private var typeFiltersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Content Types")
                .font(Typography.subheading)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(VisualPlanningType.allCases, id: \.self) { type in
                    Toggle(isOn: Binding(
                        get: { localFilters.styleCategories.contains(type.styleCategory) },
                        set: { isOn in
                            if isOn {
                                localFilters.styleCategories.append(type.styleCategory)
                            } else {
                                localFilters.styleCategories.removeAll { $0 == type.styleCategory }
                            }
                        }
                    )) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: type.icon)
                                .foregroundColor(AppColors.primary)
                                .frame(width: 20)

                            Text(type.rawValue)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    // MARK: - Date Range

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Date Range")
                .font(Typography.subheading)
                .foregroundColor(AppColors.textPrimary)

            Picker("Date Range", selection: $selectedDateRangeOption) {
                ForEach(DateRangeOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedDateRangeOption) { _, newValue in
                updateDateRange(for: newValue)
            }

            if selectedDateRangeOption == .custom {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("From:")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 50, alignment: .leading)

                        DatePicker("", selection: $customStartDate, displayedComponents: .date)
                            .labelsHidden()
                    }

                    HStack {
                        Text("To:")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 50, alignment: .leading)

                        DatePicker("", selection: $customEndDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    // MARK: - Style Filters

    private var styleFiltersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Wedding Seasons")
                .font(Typography.subheading)
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(WeddingSeason.allCases, id: \.self) { season in
                    Toggle(isOn: Binding(
                        get: { localFilters.seasons.contains(season) },
                        set: { isOn in
                            if isOn {
                                localFilters.seasons.append(season)
                            } else {
                                localFilters.seasons.removeAll { $0 == season }
                            }
                        }
                    )) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: seasonIcon(for: season))
                                .font(.caption)
                            Text(season.displayName)
                                .font(Typography.caption)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    // MARK: - Color Filters

    private var colorFiltersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Colors")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button(action: { showingColorPicker = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Color")
                    }
                    .font(Typography.caption)
                    .foregroundColor(AppColors.primary)
                }
                .buttonStyle(.plain)
            }

            if localFilters.colors.isEmpty {
                Text("No color filters applied")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.md)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: Spacing.sm) {
                    ForEach(Array(localFilters.colors.enumerated()), id: \.offset) { index, color in
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1)
                                )

                            Button(action: {
                                localFilters.colors.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.textPrimary)
                                    .background(
                                        Circle()
                                            .fill(AppColors.textPrimary.opacity(0.6))
                                            .frame(width: 16, height: 16)
                                    )
                            }
                            .buttonStyle(.plain)
                            .offset(x: 4, y: -4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .sheet(isPresented: $showingColorPicker) {
            SearchColorPickerSheet(selectedColor: $newColorToAdd) {
                localFilters.colors.append(newColorToAdd)
                showingColorPicker = false
            } onCancel: {
                showingColorPicker = false
            }
        }
    }

    // MARK: - Additional Options

    private var additionalOptionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Additional Options")
                .font(Typography.subheading)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Toggle(isOn: $localFilters.favoritesOnly) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        Text("Favorites Only")
                            .font(Typography.bodyRegular)
                    }
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $localFilters.showTemplatesOnly) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 20)
                        Text("Templates Only")
                            .font(Typography.bodyRegular)
                    }
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $localFilters.finalizedOnly) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("Finalized Only")
                            .font(Typography.bodyRegular)
                    }
                }
                .toggleStyle(.checkbox)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: Spacing.md) {
            Button("Reset All") {
                resetFilters()
            }
            .buttonStyle(.bordered)
            .disabled(!hasActiveFilters)

            Spacer()

            Text("\(activeFilterCount) active filter\(activeFilterCount == 1 ? "" : "s")")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.bordered)

            Button("Apply Filters") {
                applyFilters()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func initializeDateRange() {
        if let dateRange = localFilters.dateRange {
            customStartDate = dateRange.lowerBound
            customEndDate = dateRange.upperBound
            selectedDateRangeOption = .custom
        }
    }

    private func updateDateRange(for option: DateRangeOption) {
        let now = Date()

        switch option {
        case .allTime:
            localFilters.dateRange = nil
        case .lastWeek:
            localFilters.dateRange = Calendar.current.date(byAdding: .day, value: -7, to: now)! ... now
        case .lastMonth:
            localFilters.dateRange = Calendar.current.date(byAdding: .month, value: -1, to: now)! ... now
        case .lastYear:
            localFilters.dateRange = Calendar.current.date(byAdding: .year, value: -1, to: now)! ... now
        case .custom:
            localFilters.dateRange = customStartDate ... customEndDate
        }
    }

    private func resetFilters() {
        localFilters = SearchFilters(tenantId: localFilters.tenantId)
        selectedDateRangeOption = .allTime
        logger.info("Reset all search filters")
    }

    private func applyFilters() {
        // Update custom date range if selected
        if selectedDateRangeOption == .custom {
            localFilters.dateRange = customStartDate ... customEndDate
        }

        filters = localFilters
        logger.info("Applied search filters: \(activeFilterCount) active")
        onApply()
    }

    private var hasActiveFilters: Bool {
        !localFilters.styleCategories.isEmpty ||
        !localFilters.seasons.isEmpty ||
        !localFilters.colors.isEmpty ||
        localFilters.favoritesOnly ||
        localFilters.showTemplatesOnly ||
        localFilters.finalizedOnly ||
        localFilters.dateRange != nil
    }

    private var activeFilterCount: Int {
        var count = 0
        count += localFilters.styleCategories.count
        count += localFilters.seasons.count
        count += localFilters.colors.count
        if localFilters.favoritesOnly { count += 1 }
        if localFilters.showTemplatesOnly { count += 1 }
        if localFilters.finalizedOnly { count += 1 }
        if localFilters.dateRange != nil { count += 1 }
        return count
    }

    private func seasonIcon(for season: WeddingSeason) -> String {
        switch season {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "leaf.fill"
        case .winter: return "snowflake"
        }
    }
}

// MARK: - Supporting Types

enum VisualPlanningType: String, CaseIterable {
    case moodBoards = "Mood Boards"
    case colorPalettes = "Color Palettes"
    case seatingCharts = "Seating Charts"
    case stylePreferences = "Style Preferences"

    var icon: String {
        switch self {
        case .moodBoards: return "photo.on.rectangle.angled"
        case .colorPalettes: return "paintpalette"
        case .seatingCharts: return "tablecells"
        case .stylePreferences: return "star.square"
        }
    }

    var styleCategory: StyleCategory {
        // Map to existing StyleCategory - using a default for now
        // This would need to be adjusted based on actual StyleCategory enum
        return .romantic
    }
}

enum DateRangeOption: String, CaseIterable {
    case allTime = "All Time"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case lastYear = "Last Year"
    case custom = "Custom"

    var displayName: String {
        rawValue
    }
}

// MARK: - Search Color Picker Sheet

struct SearchColorPickerSheet: View {
    @Binding var selectedColor: Color
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Add Color Filter")
                .font(Typography.heading)

            ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 200, height: 200)

            HStack(spacing: Spacing.md) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Add Color") {
                    onAdd()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 350)
    }
}

// MARK: - Preview

#Preview {
    SearchFiltersView(
        filters: .constant(SearchFilters(tenantId: "preview")),
        onApply: {},
        onDismiss: {}
    )
}
