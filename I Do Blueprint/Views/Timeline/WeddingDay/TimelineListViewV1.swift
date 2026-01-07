//
//  TimelineListViewV1.swift
//  I Do Blueprint
//
//  Wedding Day Timeline - List View
//  Chronological expandable event list with category grouping and status indicators
//

import SwiftUI

struct TimelineListViewV1: View {
    @EnvironmentObject private var store: TimelineStoreV2

    // MARK: - State
    @State private var expandedCategories: Set<WeddingDayEventCategory> = Set(WeddingDayEventCategory.allCases)
    @State private var selectedEvent: WeddingDayEvent?
    @State private var showingEventDetail = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Summary header
                summaryHeader

                // Event list by category
                eventsByCategory
            }
            .padding()
        }
        .background(TimelineColors.auroraStart.opacity(0.3))
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                WeddingDayEventDetailSheet(event: event, onDismiss: {
                    selectedEvent = nil
                    showingEventDetail = false
                })
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: Spacing.lg) {
            // Total events card
            summaryCard(
                title: "Total Events",
                value: "\(store.weddingDayEvents.count)",
                icon: "calendar",
                color: TimelineColors.primary
            )

            // Key events card
            summaryCard(
                title: "Key Events",
                value: "\(store.keyWeddingDayEvents.count)",
                icon: "star.fill",
                color: TimelineColors.statusKeyEvent
            )

            // Pending card
            summaryCard(
                title: "Pending",
                value: "\(store.pendingWeddingDayEvents.count)",
                icon: "clock",
                color: TimelineColors.statusPending
            )

            // Duration card
            summaryCard(
                title: "Total Duration",
                value: formattedDuration(store.totalWeddingDayDuration),
                icon: "timer",
                color: TimelineColors.sage
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(value)
                .font(Typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Events By Category

    private var eventsByCategory: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(WeddingDayEventCategory.allCases, id: \.self) { category in
                let events = store.weddingDayEventsByCategory[category] ?? []

                if !events.isEmpty {
                    categorySection(category: category, events: events)
                }
            }
        }
    }

    private func categorySection(category: WeddingDayEventCategory, events: [WeddingDayEvent]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Category header (expandable)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    // Category icon
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(category.color)
                        .clipShape(Circle())

                    // Category name
                    Text(category.displayName)
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)

                    // Event count badge
                    Text("\(events.count)")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(category.color.opacity(0.8))
                        .clipShape(Capsule())

                    Spacer()

                    // Expand/collapse icon
                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Event list (when expanded)
            if expandedCategories.contains(category) {
                VStack(spacing: Spacing.sm) {
                    ForEach(events.sorted { $0.eventOrder < $1.eventOrder }) { event in
                        eventRow(event: event)
                    }
                }
                .padding(.leading, Spacing.xl)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Event Row

    private func eventRow(event: WeddingDayEvent) -> some View {
        Button {
            selectedEvent = event
            showingEventDetail = true
        } label: {
            HStack(spacing: Spacing.md) {
                // Time indicator
                timeIndicator(event: event)

                // Event content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(event.eventName)
                            .font(Typography.bodyRegular)
                            .fontWeight(event.isHighlighted ? .semibold : .regular)
                            .foregroundColor(AppColors.textPrimary)

                        if event.isMainEvent {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(TimelineColors.primary)
                        }

                        if event.status == .keyEvent {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(TimelineColors.statusKeyEvent)
                        }
                    }

                    if let venueName = event.venueName {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(venueName)
                                .font(Typography.caption)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }

                    // Duration and status
                    HStack(spacing: Spacing.md) {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(event.calculatedDurationMinutes) min")
                                .font(Typography.caption)
                        }
                        .foregroundColor(AppColors.textSecondary)

                        // Status badge
                        statusBadge(status: event.status)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding()
            .background(eventRowBackground(event: event))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(event.isHighlighted ? event.displayColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func timeIndicator(event: WeddingDayEvent) -> some View {
        VStack(spacing: 2) {
            Text(event.timeRangeDisplay)
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(event.displayColor)
        }
        .frame(width: 80, alignment: .leading)
    }

    private func statusBadge(status: WeddingDayEventStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)

            Text(status.displayName)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }

    private func eventRowBackground(event: WeddingDayEvent) -> some View {
        Group {
            if event.isHighlighted {
                LinearGradient(
                    colors: [
                        TimelineColors.cardGradientStart,
                        TimelineColors.cardGradientEnd
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                TimelineColors.glassBackground
            }
        }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        TimelineColors.glassBackground
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TimelineColors.glassBorder, lineWidth: 1)
            )
    }

    // MARK: - Helpers

    private func formattedDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Event Detail Sheet

struct WeddingDayEventDetailSheet: View {
    let event: WeddingDayEvent
    let onDismiss: () -> Void

    @EnvironmentObject private var store: TimelineStoreV2
    @Environment(\.appStores) private var appStores

    // MARK: - State
    @State private var showingVendorPicker = false
    @State private var showingGuestPicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedImage: NSImage?

    // MARK: - Computed Properties

    /// Get assigned vendors from the vendor store
    private var assignedVendors: [Vendor] {
        appStores.vendor.vendors.filter { vendor in
            event.assignedVendorIds.contains(vendor.id)
        }
    }

    /// Get assigned guests from the guest store
    private var assignedGuests: [Guest] {
        appStores.guest.guests.filter { guest in
            event.assignedGuestIds.contains(guest.id)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(event.eventName)
                        .font(Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)

                    Text(event.category.displayName)
                        .font(Typography.caption)
                        .foregroundColor(event.category.color)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding()
            .background(TimelineColors.glassBackground)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Photos section (if any)
                    if event.hasPhotos {
                        photoGallerySection
                    }

                    // Time and duration
                    detailRow(icon: "clock", title: "Time", value: event.timeRangeDisplay)
                    detailRow(icon: "timer", title: "Duration", value: "\(event.calculatedDurationMinutes) minutes")

                    // Status
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(event.status.color)
                        Text("Status")
                            .font(Typography.subheading)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: event.status.icon)
                            Text(event.status.displayName)
                        }
                        .font(Typography.bodyRegular)
                        .foregroundColor(event.status.color)
                    }

                    // Venue
                    if let venueName = event.venueName {
                        detailRow(icon: "mappin.and.ellipse", title: "Venue", value: venueName)
                    }

                    if let location = event.venueLocation {
                        detailRow(icon: "location", title: "Location", value: location)
                    }

                    // Assigned Vendors section
                    assignedVendorsSection

                    // Assigned Guests section
                    assignedGuestsSection

                    // Description
                    if let description = event.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Description")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Text(description)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }

                    // Notes
                    if let notes = event.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Notes")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Text(notes)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }

                    // Dependencies
                    if event.hasDependency, let dependencyEvent = store.dependencyEvent(for: event) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Depends On")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            HStack {
                                Image(systemName: dependencyEvent.category.icon)
                                    .foregroundColor(dependencyEvent.category.color)
                                Text(dependencyEvent.eventName)
                                    .font(Typography.bodyRegular)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                    }

                    // Dependent events
                    let dependents = store.dependentEvents(on: event)
                    if !dependents.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(AppColors.textSecondary)
                                Text("Blocks")
                                    .font(Typography.subheading)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            ForEach(dependents) { dep in
                                HStack {
                                    Image(systemName: dep.category.icon)
                                        .foregroundColor(dep.category.color)
                                    Text(dep.eventName)
                                        .font(Typography.bodyRegular)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                        }
                    }

                    // Sub-events section
                    if event.isParentEvent {
                        subEventsSection
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingVendorPicker) {
            EventVendorPickerSheet(
                event: event,
                selectedVendorIds: event.assignedVendorIds,
                onSave: { vendorIds in
                    Task {
                        await store.assignVendors(vendorIds, to: event)
                    }
                }
            )
        }
        .sheet(isPresented: $showingGuestPicker) {
            EventGuestPickerSheet(
                event: event,
                selectedGuestIds: event.assignedGuestIds,
                onSave: { guestIds in
                    Task {
                        await store.assignGuests(guestIds, to: event)
                    }
                }
            )
        }
    }

    // MARK: - Photo Gallery Section

    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "photo.stack")
                    .foregroundColor(AppColors.textSecondary)
                Text("Photos")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Text("\(event.photoUrls.count)")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(event.photoUrls, id: \.self) { photoUrl in
                        AsyncImage(url: URL(string: photoUrl)) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.cardBackground)
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.cardBackground)
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Assigned Vendors Section

    private var assignedVendorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(TimelineColors.sage)
                Text("Assigned Vendors")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Button {
                    showingVendorPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Edit")
                    }
                    .font(Typography.caption)
                    .foregroundColor(TimelineColors.primary)
                }
                .buttonStyle(.plain)
            }

            if assignedVendors.isEmpty {
                Text("No vendors assigned")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .italic()
            } else {
                ForEach(assignedVendors, id: \.id) { vendor in
                    HStack(spacing: Spacing.sm) {
                        // Vendor avatar or icon
                        ZStack {
                            Circle()
                                .fill(TimelineColors.sage.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 14))
                                .foregroundColor(TimelineColors.sage)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(vendor.vendorName)
                                .font(Typography.bodyRegular)
                                .foregroundColor(AppColors.textPrimary)
                            if let vendorType = vendor.vendorType {
                                Text(vendorType)
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Assigned Guests Section

    private var assignedGuestsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(TimelineColors.blush)
                Text("Assigned Guests")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Button {
                    showingGuestPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Edit")
                    }
                    .font(Typography.caption)
                    .foregroundColor(TimelineColors.primary)
                }
                .buttonStyle(.plain)
            }

            if assignedGuests.isEmpty {
                Text("No guests assigned")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .italic()
            } else {
                // Show first 5 guests, then count
                let displayGuests = Array(assignedGuests.prefix(5))
                ForEach(displayGuests, id: \.id) { guest in
                    HStack(spacing: Spacing.sm) {
                        // Guest avatar
                        ZStack {
                            Circle()
                                .fill(TimelineColors.blush.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Text(guest.initials)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(TimelineColors.blush)
                        }

                        Text(guest.fullName)
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.vertical, 2)
                }

                if assignedGuests.count > 5 {
                    Text("+ \(assignedGuests.count - 5) more guests")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Sub-Events Section

    private var subEventsSection: some View {
        let subEvents = store.weddingDayEvents.filter { $0.parentEventId == event.id }

        return Group {
            if !subEvents.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "list.bullet.indent")
                            .foregroundColor(AppColors.textSecondary)
                        Text("Sub-Events")
                            .font(Typography.subheading)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("\(subEvents.count)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    ForEach(subEvents) { subEvent in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: subEvent.category.icon)
                                .foregroundColor(subEvent.category.color)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(subEvent.eventName)
                                    .font(Typography.bodyRegular)
                                    .foregroundColor(AppColors.textPrimary)
                                Text(subEvent.timeRangeDisplay)
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }

                            Spacer()

                            Circle()
                                .fill(subEvent.status.color)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
            Text(title)
                .font(Typography.subheading)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Vendor Picker Sheet

struct EventVendorPickerSheet: View {
    let event: WeddingDayEvent
    let selectedVendorIds: [Int64]
    let onSave: ([Int64]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appStores) private var appStores
    @State private var selectedIds: Set<Int64>
    @State private var searchText = ""

    init(event: WeddingDayEvent, selectedVendorIds: [Int64], onSave: @escaping ([Int64]) -> Void) {
        self.event = event
        self.selectedVendorIds = selectedVendorIds
        self.onSave = onSave
        self._selectedIds = State(initialValue: Set(selectedVendorIds))
    }

    private var filteredVendors: [Vendor] {
        let vendors = appStores.vendor.vendors.filter { !$0.isArchived }
        if searchText.isEmpty {
            return vendors
        }
        return vendors.filter { vendor in
            vendor.vendorName.localizedCaseInsensitiveContains(searchText) ||
            (vendor.vendorType?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assign Vendors")
                    .font(Typography.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    onSave(Array(selectedIds))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                TextField("Search vendors...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(Spacing.sm)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)

            // Vendor list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredVendors, id: \.id) { vendor in
                        VendorPickerRow(
                            vendor: vendor,
                            isSelected: selectedIds.contains(vendor.id),
                            onToggle: {
                                if selectedIds.contains(vendor.id) {
                                    selectedIds.remove(vendor.id)
                                } else {
                                    selectedIds.insert(vendor.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct VendorPickerRow: View {
    let vendor: Vendor
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? TimelineColors.primary : AppColors.textSecondary)

                // Vendor info
                VStack(alignment: .leading, spacing: 2) {
                    Text(vendor.vendorName)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                    if let vendorType = vendor.vendorType {
                        Text(vendorType)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                // Booked indicator
                if vendor.isBooked == true {
                    Text("Booked")
                        .font(Typography.caption)
                        .foregroundColor(TimelineColors.statusReady)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(TimelineColors.statusReady.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Guest Picker Sheet

struct EventGuestPickerSheet: View {
    let event: WeddingDayEvent
    let selectedGuestIds: [UUID]
    let onSave: ([UUID]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appStores) private var appStores
    @State private var selectedIds: Set<UUID>
    @State private var searchText = ""

    init(event: WeddingDayEvent, selectedGuestIds: [UUID], onSave: @escaping ([UUID]) -> Void) {
        self.event = event
        self.selectedGuestIds = selectedGuestIds
        self.onSave = onSave
        self._selectedIds = State(initialValue: Set(selectedGuestIds))
    }

    private var filteredGuests: [Guest] {
        let guests = appStores.guest.guests
        if searchText.isEmpty {
            return guests
        }
        return guests.filter { guest in
            guest.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assign Guests")
                    .font(Typography.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    onSave(Array(selectedIds))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                TextField("Search guests...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(Spacing.sm)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)

            // Selection summary
            HStack {
                Text("\(selectedIds.count) guests selected")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                if !selectedIds.isEmpty {
                    Button("Clear All") {
                        selectedIds.removeAll()
                    }
                    .font(Typography.caption)
                    .foregroundColor(TimelineColors.primary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.sm)

            // Guest list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredGuests, id: \.id) { guest in
                        GuestPickerRow(
                            guest: guest,
                            isSelected: selectedIds.contains(guest.id),
                            onToggle: {
                                if selectedIds.contains(guest.id) {
                                    selectedIds.remove(guest.id)
                                } else {
                                    selectedIds.insert(guest.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct GuestPickerRow: View {
    let guest: Guest
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? TimelineColors.primary : AppColors.textSecondary)

                // Guest avatar
                ZStack {
                    Circle()
                        .fill(TimelineColors.blush.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text(guest.initials)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TimelineColors.blush)
                }

                // Guest info
                VStack(alignment: .leading, spacing: 2) {
                    Text(guest.fullName)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                    Text(guest.rsvpStatus.displayName)
                        .font(Typography.caption)
                        .foregroundColor(guest.rsvpStatus.color)
                }

                Spacer()
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TimelineListViewV1()
        .environmentObject(TimelineStoreV2())
        .frame(width: 1000, height: 800)
}
