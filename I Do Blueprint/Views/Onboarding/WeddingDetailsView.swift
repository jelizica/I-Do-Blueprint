//
//  WeddingDetailsView.swift
//  I Do Blueprint
//
//  Wedding details form for onboarding
//

import SwiftUI
import Combine

struct WeddingDetailsView: View {
    @Environment(\.onboardingStore) private var store

    @State private var partner1Name: String = ""
    @State private var partner1Nickname: String = ""
    @State private var partner2Name: String = ""
    @State private var partner2Nickname: String = ""
    @State private var venue: String = ""
    @State private var weddingDate: Date?
    @State private var isDateTBD: Bool = false
    @State private var selectedStyle: WeddingStyle?
    @State private var estimatedGuestCount: String = ""
    @State private var showDatePicker = false
    @State private var weddingEvents: [OnboardingWeddingEvent] = []
    @State private var validationTask: Task<Void, Never>?

    // Computed property for validation
    private var isValid: Bool {
        !partner1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !partner2Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (isDateTBD || weddingDate != nil) // Date required unless TBD
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                headerSection
                formSection
            }
        }
        .background(AppColors.background)
        .onAppear {
            loadExistingData()
        }
        .onChange(of: partner1Name) { _ in scheduleValidationUpdate() }
        .onChange(of: partner2Name) { _ in scheduleValidationUpdate() }
        .onChange(of: isDateTBD) { _ in scheduleValidationUpdate() }
        .onChange(of: weddingDate) { _ in scheduleValidationUpdate() }
        .onDisappear {
            validationTask?.cancel()
            saveDetails()
        }
    }

    // MARK: - View Sections

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Wedding Details")
                .font(Typography.title1)
                .foregroundColor(AppColors.textPrimary)

            Text("Tell us about your special day")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, Spacing.xl)
    }

    private var formSection: some View {
        VStack(spacing: Spacing.lg) {
            partnerNamesSection
            Divider().padding(.vertical, Spacing.sm)
            weddingDateSection
            Divider().padding(.vertical, Spacing.sm)
            venueSection

            // Show optional fields only in guided mode
            if store.selectedMode == .guided {
                Divider().padding(.vertical, Spacing.sm)
                weddingEventsSection
                Divider().padding(.vertical, Spacing.sm)
                weddingStyleSection
                Divider().padding(.vertical, Spacing.sm)
                guestCountSection
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xxl)
    }

    private var partnerNamesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormSectionHeader(title: "Partners", isRequired: true)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                FormTextField(
                    title: "Partner 1 Full Name",
                    text: $partner1Name,
                    placeholder: "Enter first partner's full name",
                    isRequired: true
                )

                FormTextField(
                    title: "Partner 1 Nickname (Optional)",
                    text: $partner1Nickname,
                    placeholder: "e.g., Alex, Sam",
                    isRequired: false
                )
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                FormTextField(
                    title: "Partner 2 Full Name",
                    text: $partner2Name,
                    placeholder: "Enter second partner's full name",
                    isRequired: true
                )

                FormTextField(
                    title: "Partner 2 Nickname (Optional)",
                    text: $partner2Nickname,
                    placeholder: "e.g., Chris, Jordan",
                    isRequired: false
                )
            }
        }
    }

    private var weddingDateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                FormSectionHeader(title: "Wedding Date", isRequired: !isDateTBD)

                Spacer()

                Toggle("Date TBD", isOn: $isDateTBD)
                    .toggleStyle(.checkbox)
                    .help("Check if wedding date is to be determined")
            }

            if !isDateTBD {
                datePickerButton

                if showDatePicker {
                    datePicker
                }
            } else {
                Text("Wedding date is to be determined")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
            }
        }
    }

    private var datePickerButton: some View {
        Button(action: { showDatePicker.toggle() }) {
            HStack {
                let dateText = weddingDate.map { formatDate($0) } ?? "Select date"
                let textColor = weddingDate == nil ? AppColors.textSecondary : AppColors.textPrimary

                Text(dateText)
                    .foregroundColor(textColor)

                Spacer()

                Image(systemName: "calendar")
                    .foregroundColor(AppColors.primary)
            }
            .font(Typography.bodyRegular)
            .padding(Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
        }
        .accessibilityLabel("Wedding date")
        .accessibilityValue(weddingDate.map { formatDate($0) } ?? "Not selected")
        .accessibilityHint("Tap to select a date")
    }

    private var datePicker: some View {
        let defaultDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
        let binding = Binding<Date>(
            get: { weddingDate ?? defaultDate },
            set: { newDate in
                weddingDate = newDate
                updateStoreForValidation()
            }
        )

        return DatePicker(
            "Select Date",
            selection: binding,
            in: Date()...,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }

    private var venueSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormSectionHeader(title: "Venue", isRequired: false)

            FormTextField(
                title: "Venue Name",
                text: $venue,
                placeholder: "Enter venue name or location",
                isRequired: false
            )
        }
    }

    private var weddingStyleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormSectionHeader(title: "Wedding Style", isRequired: false)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(WeddingStyle.allCases, id: \.self) { style in
                    WeddingStyleCard(
                        style: style,
                        isSelected: store.weddingDetails.weddingStyle == style,
                        onSelect: { store.weddingDetails.weddingStyle = style }
                    )
                }
            }
        }
    }

    private var weddingEventsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormSectionHeader(title: "Wedding Events (Optional)", isRequired: false)

            Text("Configure your ceremony and reception details")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)

            if weddingEvents.isEmpty {
                Button(action: initializeDefaultEvents) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Default Events")
                    }
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.primary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else {
                ForEach($weddingEvents) { $event in
                    WeddingEventCard(event: $event, weddingDate: weddingDate)
                }
            }
        }
    }

    private var guestCountSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FormSectionHeader(title: "Estimated Guest Count", isRequired: false)

            FormTextField(
                title: "Number of Guests",
                text: $estimatedGuestCount,
                placeholder: "e.g., 100",
                isRequired: false
            )
        }
    }

    // MARK: - Helper Methods

    private func loadExistingData() {
        let details = store.weddingDetails
        partner1Name = details.partner1Name
        partner1Nickname = details.partner1Nickname
        partner2Name = details.partner2Name
        partner2Nickname = details.partner2Nickname
        venue = details.venue
        weddingDate = details.weddingDate
        isDateTBD = details.isWeddingDateTBD
        selectedStyle = details.weddingStyle
        weddingEvents = details.weddingEvents
        if let count = details.estimatedGuestCount {
            estimatedGuestCount = "\(count)"
        }
    }

    private func initializeDefaultEvents() {
        weddingEvents = [
            .defaultCeremony(),
            .defaultReception()
        ]
    }

    /// Schedule a debounced validation update to avoid triggering during view updates
    private func scheduleValidationUpdate() {
        // Cancel any pending validation
        validationTask?.cancel()

        // Schedule new validation task with debounce
        validationTask = Task { @MainActor in
            // Small delay to ensure we're outside the view update cycle
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms debounce

            guard !Task.isCancelled else { return }

            // Now safe to update store
            updateStoreForValidation()
        }
    }

    private func updateStoreForValidation() {
        // Update the full details object in the store for real-time validation
        let details = WeddingDetails(
            weddingDate: isDateTBD ? nil : weddingDate,
            isWeddingDateTBD: isDateTBD,
            venue: venue,
            partner1Name: partner1Name,
            partner1Nickname: partner1Nickname,
            partner2Name: partner2Name,
            partner2Nickname: partner2Nickname,
            weddingStyle: selectedStyle,
            estimatedGuestCount: Int(estimatedGuestCount),
            weddingEvents: weddingEvents
        )

        // Update store's weddingDetails for validation
        store.weddingDetails = details
    }

    private func saveDetails() {
        // Create the complete details object
        let details = WeddingDetails(
            weddingDate: isDateTBD ? nil : weddingDate,
            isWeddingDateTBD: isDateTBD,
            venue: venue,
            partner1Name: partner1Name,
            partner1Nickname: partner1Nickname,
            partner2Name: partner2Name,
            partner2Nickname: partner2Nickname,
            weddingStyle: selectedStyle,
            estimatedGuestCount: Int(estimatedGuestCount),
            weddingEvents: weddingEvents
        )

        // Save to store
        Task {
            await store.saveWeddingDetails(details)
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "Select date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Form Components

struct FormSectionHeader: View {
    let title: String
    let isRequired: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .font(Typography.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            if isRequired {
                Text("*")
                    .font(Typography.bodyLarge)
                    .foregroundColor(AppColors.error)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isRequired ? "\(title), required" : title)
    }
}

struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isRequired: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
                .padding(Spacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
                .accessibilityLabel(title)
                .accessibilityValue(text.isEmpty ? "Empty" : text)
                .accessibilityHint(isRequired ? "Required field" : "Optional field")
        }
    }
}

struct WeddingStyleCard: View {
    let style: WeddingStyle
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: style.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)

                Text(style.displayName)
                    .font(Typography.bodySmall)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(style.displayName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Tap to select \(style.displayName) style")
    }
}

// MARK: - Preview

#Preview("Wedding Details View") {
    WeddingDetailsView()
}

#Preview("Wedding Style Card - Selected") {
    WeddingStyleCard(
        style: .modern,
        isSelected: true,
        onSelect: {}
    )
    .padding()
    .frame(width: 150)
}

// MARK: - Wedding Event Card

struct WeddingEventCard: View {
    @Binding var event: OnboardingWeddingEvent
    let weddingDate: Date?
    @State private var showDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                TextField("Event Name", text: $event.eventName)
                    .font(Typography.bodyLarge)
                    .fontWeight(.semibold)

                if event.isMainEvent {
                    Text("Main Event")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(AppColors.primary)
                        .cornerRadius(4)
                }
            }

            TextField("Venue Location (Optional)", text: $event.venueLocation)
                .font(Typography.bodyRegular)
                .textFieldStyle(.plain)
                .padding(Spacing.sm)
                .background(AppColors.background)
                .cornerRadius(4)

            HStack(spacing: Spacing.md) {
                Button(action: { showDatePicker.toggle() }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text(event.eventDate.map { formatDate($0) } ?? "Set Date")
                            .font(Typography.bodySmall)
                    }
                    .foregroundColor(event.eventDate == nil ? AppColors.textSecondary : AppColors.textPrimary)
                }
                .buttonStyle(.plain)

                TextField("Time (e.g., 3:00 PM)", text: $event.eventTime)
                    .font(Typography.bodySmall)
                    .textFieldStyle(.plain)
                    .padding(Spacing.sm)
                    .background(AppColors.background)
                    .cornerRadius(4)
            }

            if showDatePicker {
                DatePicker(
                    "Event Date",
                    selection: Binding(
                        get: { event.eventDate ?? weddingDate ?? Date() },
                        set: { newDate in
                            event.eventDate = newDate
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(Spacing.sm)
                .background(AppColors.background)
                .cornerRadius(4)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview("Wedding Style Card - Unselected") {
    WeddingStyleCard(
        style: .rustic,
        isSelected: false,
        onSelect: {}
    )
    .padding()
    .frame(width: 150)
}
