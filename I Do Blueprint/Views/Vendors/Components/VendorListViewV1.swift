//
//  VendorListViewV1.swift
//  I Do Blueprint
//
//  V1 of Vendor List View - Alternate list-based display for vendor management
//  Features:
//  - List rows with avatar, name, category, status badge, quoted amount
//  - Expandable detail section with contact, mini-timeline, payment status, notes
//  - Glassmorphism styling consistent with V4 design system
//  - Theme-aware colors and accessibility support
//

import SwiftUI

// MARK: - Vendor List View V1

struct VendorListViewV1: View {
    let windowSize: WindowSize
    let loadingState: LoadingState<[Vendor]>
    let filteredVendors: [Vendor]
    let searchText: String
    let selectedFilter: VendorFilterOption
    @Binding var selectedVendor: Vendor?
    @Binding var showingAddVendor: Bool
    let onRetry: () async -> Void
    let onClearFilters: () -> Void

    @State private var expandedVendorId: Int64?

    var body: some View {
        Group {
            switch loadingState {
            case .idle:
                loadingView

            case .loading:
                loadingView

            case .loaded:
                if filteredVendors.isEmpty {
                    if searchText.isEmpty && selectedFilter == .all {
                        emptyStateView
                    } else {
                        noResultsForFilterView
                    }
                } else {
                    vendorListContent
                }

            case .error(let error):
                errorView(error: error)
            }
        }
    }

    // MARK: - Vendor List Content

    private var vendorListContent: some View {
        VStack(spacing: 0) {
            // Glass panel container for the list
            VStack(spacing: Spacing.sm) {
                ForEach(filteredVendors) { vendor in
                    VendorListRowV1(
                        vendor: vendor,
                        isExpanded: expandedVendorId == vendor.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedVendorId == vendor.id {
                                    expandedVendorId = nil
                                } else {
                                    expandedVendorId = vendor.id
                                }
                            }
                        },
                        onMoreTap: {
                            selectedVendor = vendor
                        }
                    )
                }
            }
            .padding(Spacing.lg)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.white.opacity(0.25))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading vendors...")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Circle()
                .fill(SemanticColors.primaryAction.opacity(Opacity.light))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(SemanticColors.primaryAction)
                )

            VStack(spacing: Spacing.sm) {
                Text("No Vendors Yet")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Add your first vendor to start tracking your wedding services")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                showingAddVendor = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Vendor")
                }
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.primaryAction)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }

    // MARK: - No Results for Filter View

    private var noResultsForFilterView: some View {
        VStack(spacing: Spacing.xl) {
            Circle()
                .fill(filterIconColor.opacity(Opacity.light))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: filterIconName)
                        .font(.system(size: 32))
                        .foregroundColor(filterIconColor)
                )

            VStack(spacing: Spacing.sm) {
                Text(filterEmptyTitle)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(filterEmptyMessage)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            if !searchText.isEmpty {
                Button {
                    onClearFilters()
                } label: {
                    Text("Clear Search")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.primaryAction)
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.white.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(SemanticColors.primaryAction, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    onClearFilters()
                } label: {
                    Text("View All Vendors")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.primaryAction)
                        .padding(.horizontal, Spacing.xxl)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(Color.white.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(SemanticColors.primaryAction, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }

    // MARK: - Filter-specific UI helpers

    private var filterIconName: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        switch selectedFilter {
        case .all:
            return "building.2"
        case .available:
            return "clock"
        case .booked:
            return "checkmark.circle"
        case .archived:
            return "archivebox"
        }
    }

    private var filterIconColor: Color {
        if !searchText.isEmpty {
            return SemanticColors.textSecondary
        }
        switch selectedFilter {
        case .all:
            return SemanticColors.primaryAction
        case .available:
            return SemanticColors.statusPending
        case .booked:
            return SemanticColors.statusSuccess
        case .archived:
            return SemanticColors.textSecondary
        }
    }

    private var filterEmptyTitle: String {
        if !searchText.isEmpty {
            return "No Matching Vendors"
        }
        switch selectedFilter {
        case .all:
            return "No Vendors Found"
        case .available:
            return "No Available Vendors"
        case .booked:
            return "No Booked Vendors"
        case .archived:
            return "No Archived Vendors"
        }
    }

    private var filterEmptyMessage: String {
        if !searchText.isEmpty {
            return "No vendors match your search for \"\(searchText)\". Try a different search term or clear the search."
        }
        switch selectedFilter {
        case .all:
            return "Add vendors to start tracking your wedding services."
        case .available:
            return "All your vendors are either booked or archived. Add new vendors to see them here."
        case .booked:
            return "You haven't booked any vendors yet. Mark vendors as booked when you've confirmed them."
        case .archived:
            return "You don't have any archived vendors. Archive vendors you're no longer considering."
        }
    }

    // MARK: - Error View

    private func errorView(error: Error) -> some View {
        VStack(spacing: Spacing.xl) {
            Circle()
                .fill(SemanticColors.statusError.opacity(Opacity.light))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(SemanticColors.statusError)
                )

            VStack(spacing: Spacing.sm) {
                Text("Error Loading Vendors")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(error.localizedDescription)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                Task {
                    await onRetry()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.primaryAction)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }
}

// MARK: - Vendor List Row V1

struct VendorListRowV1: View {
    let vendor: Vendor
    let isExpanded: Bool
    let onTap: () -> Void
    let onMoreTap: () -> Void

    @State private var isHovered = false
    @State private var loadedImage: NSImage?

    // Generate initials from vendor name
    private var initials: String {
        let words = vendor.vendorName.split(separator: " ")
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let firstWord = words.first {
            return String(firstWord.prefix(2)).uppercased()
        }
        return "V"
    }

    // Generate a consistent color based on vendor name
    private var avatarColor: Color {
        let colors: [Color] = [
            AppGradients.weddingPink,
            AppGradients.sageGreen,
            SemanticColors.primaryAction,
            Color.fromHex("9370DB"), // Purple
            Color.fromHex("E8A87C"), // Peach
            Color.fromHex("5DADE2")  // Blue
        ]
        let hash = vendor.vendorName.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            mainRowContent
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }

            // Expanded detail section
            if isExpanded {
                expandedDetailSection
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? CornerRadius.xl : CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? CornerRadius.xl : CornerRadius.lg)
                .stroke(
                    isExpanded
                        ? SemanticColors.primaryAction.opacity(0.2)
                        : (isHovered ? Color.white.opacity(0.4) : Color.clear),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(isExpanded ? 0.1 : (isHovered ? 0.06 : 0.03)),
            radius: isExpanded ? 12 : (isHovered ? 8 : 4),
            x: 0,
            y: isExpanded ? 4 : 2
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibleListItem(
            label: vendor.vendorName,
            hint: isExpanded ? "Tap to collapse details" : "Tap to expand details",
            value: vendor.isBooked == true ? "Booked" : "Available"
        )
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }

    // MARK: - Main Row Content

    private var mainRowContent: some View {
        HStack(spacing: Spacing.lg) {
            // Avatar
            avatarView

            // Vendor info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(vendor.vendorName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                    Text(vendorType)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status badge
            statusBadge

            // Quoted amount
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("Quoted Amount")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(formatCurrency(vendor.quotedAmount ?? 0))
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // More button
            Button {
                onMoreTap()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        Circle()
            .fill(avatarColor.opacity(0.2))
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
                        Text(initials)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(avatarColor)
                    }
                }
            )
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Group {
            if vendor.isArchived {
                VendorStatusBadgeV1(text: "Archived", style: .archived)
            } else if vendor.isBooked == true {
                VendorStatusBadgeV1(text: "Booked", style: .booked)
            } else {
                VendorStatusBadgeV1(text: "Available", style: .available)
            }
        }
    }

    // MARK: - Row Background

    private var rowBackground: some View {
        ZStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.white.opacity(0.35))
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.white.opacity(isHovered ? 0.35 : 0.25))
            }
        }
    }

    // MARK: - Expanded Detail Section

    private var expandedDetailSection: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)

            // Detail content
            HStack(alignment: .top, spacing: Spacing.xxl) {
                // Contact section
                contactSection

                // Mini-timeline section
                miniTimelineSection

                // Payment status and notes section
                paymentAndNotesSection
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(SemanticColors.backgroundSecondary.opacity(0.8))
            )
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("CONTACT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let email = vendor.email, !email.isEmpty {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textSecondary)
                            .frame(width: 20)

                        Text(email)
                            .font(Typography.bodySmall)
                            .foregroundColor(SemanticColors.textPrimary)
                            .lineLimit(1)
                    }
                }

                if let phone = vendor.phoneNumber, !phone.isEmpty {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textSecondary)
                            .frame(width: 20)

                        Text(phone)
                            .font(Typography.bodySmall)
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                }

                if vendor.email == nil && vendor.phoneNumber == nil {
                    Text("No contact info")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textTertiary)
                        .italic()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Mini-Timeline Section

    private var miniTimelineSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("MINI-TIMELINE")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Created date
                TimelineItemV1(
                    icon: "plus.circle.fill",
                    text: "Added \(formatRelativeDate(vendor.createdAt))",
                    isFirst: true
                )

                // Updated date (if different from created)
                if let updatedAt = vendor.updatedAt, updatedAt != vendor.createdAt {
                    TimelineItemV1(
                        icon: "pencil.circle.fill",
                        text: "Updated \(formatRelativeDate(updatedAt))",
                        isFirst: false
                    )
                }

                // Booked date
                if let dateBooked = vendor.dateBooked {
                    TimelineItemV1(
                        icon: "calendar.badge.checkmark",
                        text: "Booked \(formatRelativeDate(dateBooked))",
                        isFirst: false,
                        isHighlighted: true
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Payment and Notes Section

    private var paymentAndNotesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Payment status
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("PAYMENT STATUS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)

                // For now, show a placeholder - this would be connected to payment data
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.statusPending)

                    Text("Pending")
                        .font(Typography.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.statusPending)
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("NOTES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)

                Text(vendor.notes?.isEmpty == false ? vendor.notes! : "No notes added.")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helper Methods

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

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Vendor Status Badge V1

struct VendorStatusBadgeV1: View {
    let text: String
    let style: BadgeStyle

    enum BadgeStyle {
        case booked
        case available
        case archived

        var backgroundColor: Color {
            switch self {
            case .booked:
                return SemanticColors.statusSuccess.opacity(Opacity.light)
            case .available:
                return SemanticColors.statusPending.opacity(Opacity.light)
            case .archived:
                return SemanticColors.textSecondary.opacity(Opacity.light)
            }
        }

        var textColor: Color {
            switch self {
            case .booked:
                return SemanticColors.statusSuccess
            case .available:
                return SemanticColors.statusPending
            case .archived:
                return SemanticColors.textSecondary
            }
        }
    }

    var body: some View {
        Text(text)
            .font(Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(style.textColor)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
            )
    }
}

// MARK: - Timeline Item V1

struct TimelineItemV1: View {
    let icon: String
    let text: String
    let isFirst: Bool
    var isHighlighted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Timeline dot/icon
            ZStack {
                if !isFirst {
                    // Vertical line connecting to previous item
                    Rectangle()
                        .fill(SemanticColors.borderLight)
                        .frame(width: 1)
                        .offset(y: -12)
                }

                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isHighlighted ? SemanticColors.primaryAction : SemanticColors.textSecondary)
            }
            .frame(width: 16, height: 16)

            Text(text)
                .font(Typography.bodySmall)
                .foregroundColor(isHighlighted ? SemanticColors.textPrimary : SemanticColors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VendorListViewV1(
        windowSize: .large,
        loadingState: .loaded([]),
        filteredVendors: [],
        searchText: "",
        selectedFilter: .all,
        selectedVendor: .constant(nil),
        showingAddVendor: .constant(false),
        onRetry: {},
        onClearFilters: {}
    )
    .padding()
    .background(MeshGradientBackgroundView())
}
