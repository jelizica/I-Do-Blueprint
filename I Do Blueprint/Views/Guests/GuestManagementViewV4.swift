//
//  GuestManagementViewV4.swift
//  I Do Blueprint
//
//  Modern guest management view with Supabase integration
//

import SwiftUI
import Dependencies

struct GuestManagementViewV4: View {
    @Environment(\.appStores) private var appStores
    @Environment(\.guestStore) private var guestStore
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator

    @State private var searchText = ""
    @State private var selectedStatus: RSVPStatus?
    @State private var selectedInvitedBy: InvitedBy?
    @State private var selectedSortOption: GuestSortOption = .nameAsc
    @State private var showingImportSheet = false
    @State private var showingExportSheet = false
    /// Local render token that forces the guest grid to rebuild when the store's
    /// guestListVersion changes after a reload.
    @State private var guestListRenderId: Int = 0

    private var settings: CoupleSettings {
        settingsStore.settings
    }

    private var weddingTitle: String {
        let partner1 = settings.global.partner1Nickname.isEmpty
            ? settings.global.partner1FullName
            : settings.global.partner1Nickname
        let partner2 = settings.global.partner2Nickname.isEmpty
            ? settings.global.partner2FullName
            : settings.global.partner2Nickname

        if !partner1.isEmpty && !partner2.isEmpty {
            return "\(partner1) & \(partner2)'s Wedding"
        }
        return "Wedding"
    }

    private var weddingDate: String {
        if settings.global.isWeddingDateTBD {
            return "Date TBD"
        }

        guard !settings.global.weddingDate.isEmpty else {
            return "Date TBD"
        }

        // Format the date nicely
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: settings.global.weddingDate) {
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }

        return settings.global.weddingDate
    }


    
    var body: some View {
        ZStack {
            AppGradients.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky Header Section
                headerSection
                    .padding(.horizontal, Spacing.huge)
                    .padding(.top, Spacing.xxxl)
                    .padding(.bottom, Spacing.xxl)

                // Scrollable Content Section
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Stats Cards
                        statsSection

                        // Search and Filters
                        searchAndFiltersSection

                        // Guest List
                        guestListSection
                    }
                    .padding(.horizontal, Spacing.huge)
                    .padding(.bottom, Spacing.huge)
                }
            }
        }
        .navigationTitle("Guest Management")
        .sheet(isPresented: $showingImportSheet) {
            GuestCSVImportView()
                .environmentObject(guestStore)
        }
        .sheet(isPresented: $showingExportSheet) {
            GuestExportView(
                guests: filteredAndSortedGuests,
                settings: settings,
                onExportSuccessful: { fileURL, format in
                    // Open the exported file
                    GuestExportService.shared.openFile(fileURL)
                    
                    // Show success alert
                    GuestExportService.shared.showExportSuccessAlert(
                        format: format,
                        fileURL: fileURL
                    ) { _ in
                        // Alert dismissed
                    }
                }
            )
        }
        .task {
            if guestStore.loadingState.isIdle {
                await guestStore.loadGuestData()
            }
        }
                .onChange(of: guestStore.guestListVersion) { _ in
            // Force the grid to rebuild when the underlying list reloads
            guestListRenderId &+= 1
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 0) {
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Guest Management")
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)

                Text("Manage and track all your guests in one place")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 12) {
                // Import Button
                Button {
                    showingImportSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                        Text("Import")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 42)
                    .padding(.horizontal, Spacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.borderLight, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                // Export Button
                Button {
                    exportGuestList()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("Export")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 42)
                    .padding(.horizontal, Spacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.borderLight, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                // Add Guest Button
                Button {
                    coordinator.present(.addGuest)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Guest")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 42)
                    .padding(.horizontal, Spacing.xl)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 68)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: Spacing.lg) {
            // Main Stats Row
            HStack(spacing: Spacing.lg) {
                GuestManagementStatCard(
                    title: "Total Guests",
                    value: "\(guestStore.totalGuestsCount)",
                    subtitle: guestStore.weeklyChange > 0 ? "+\(guestStore.weeklyChange) this week" : nil,
                    subtitleColor: AppColors.success,
                    icon: "person.3.fill"
                )

                GuestManagementStatCard(
                    title: "Acceptance Rate",
                    value: "\(Int(guestStore.acceptanceRate * 100))%",
                    subtitle: "\(guestStore.attendingCount) confirmed",
                    subtitleColor: AppColors.success,
                    icon: "checkmark.circle.fill"
                )
            }

            // Sub-sections Row
            HStack(spacing: Spacing.lg) {
                GuestManagementStatCard(
                    title: "Attending",
                    value: "\(guestStore.attendingCount)",
                    subtitle: "Confirmed & Attending",
                    subtitleColor: AppColors.success,
                    icon: "checkmark.circle.fill"
                )

                GuestManagementStatCard(
                    title: "Pending",
                    value: "\(guestStore.pendingCount)",
                    subtitle: "All other statuses",
                    subtitleColor: AppColors.warning,
                    icon: "clock.fill"
                )

                GuestManagementStatCard(
                    title: "Declined",
                    value: "\(guestStore.declinedCount)",
                    subtitle: "Declined & No Response",
                    subtitleColor: AppColors.error,
                    icon: "xmark.circle.fill"
                )
            }
        }
    }

    // MARK: - Search and Filters Section

    private var searchAndFiltersSection: some View {
        VStack(spacing: Spacing.md) {
            // Single Row: Search + Status Toggles + Invited By Toggles + Sort + Clear
            HStack(spacing: Spacing.sm) {
                // Search Field
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.body)

                    TextField("Search guests...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.sm)
                .frame(width: 200)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                )

                // RSVP Status Toggle Buttons (Blue - Primary)
                ForEach([nil, RSVPStatus.attending, RSVPStatus.pending, RSVPStatus.declined], id: \.self) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        Text(status?.displayName ?? "All Status")
                            .font(Typography.bodySmall)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(selectedStatus == status ? AppColors.primary : AppColors.cardBackground)
                    )
                    .foregroundColor(selectedStatus == status ? .white : AppColors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .stroke(selectedStatus == status ? AppColors.primary : AppColors.border, lineWidth: 1)
                    )
                }

                // Invited By Toggle Buttons (Teal - Different color to differentiate)
                ForEach([nil] + InvitedBy.allCases, id: \.self) { invitedBy in
                    Button {
                        selectedInvitedBy = invitedBy
                    } label: {
                        Text(invitedBy?.displayName(with: settings) ?? "All Guests")
                            .font(Typography.bodySmall)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(selectedInvitedBy == invitedBy ? Color.teal : AppColors.cardBackground)
                    )
                    .foregroundColor(selectedInvitedBy == invitedBy ? .white : AppColors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .stroke(selectedInvitedBy == invitedBy ? Color.teal : AppColors.border, lineWidth: 1)
                    )
                }

                Spacer()

                // Sort Menu
                Menu {
                    ForEach(GuestSortOption.grouped, id: \.0) { group in
                        Section(group.0) {
                            ForEach(group.1) { option in
                                Button {
                                    selectedSortOption = option
                                } label: {
                                    HStack {
                                        Label(option.displayName, systemImage: option.iconName)
                                        if selectedSortOption == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(selectedSortOption.groupLabel)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(Typography.bodySmall)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.bordered)
                .help("Sort guests")

                // Clear Filters
                if selectedStatus != nil || selectedInvitedBy != nil || !searchText.isEmpty {
                    Button {
                        searchText = ""
                        selectedStatus = nil
                        selectedInvitedBy = nil
                    } label: {
                        Text("Clear")
                            .font(Typography.bodySmall)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(AppColors.primary)
                }
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }


    // MARK: - Guest List Section

    private var guestListSection: some View {
        Group {
            if guestStore.isLoading {
                ProgressView("Loading guests...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = guestStore.error {
                ErrorView(error: error) {
                    Task {
                        await guestStore.retryLoad()
                    }
                }
            } else if filteredAndSortedGuests.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg)
                ], spacing: Spacing.lg) {
                    ForEach(filteredAndSortedGuests, id: \.id) { guest in
                        GuestCardV4(guest: guest, settings: settings)
                            .onTapGesture {
                                coordinator.present(.editGuest(guest))
                            }
                    }
                }
                .id(guestListRenderId)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textTertiary)

            Text("No guests found")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Text("Add your first guest to get started")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)

            Button {
                coordinator.present(.addGuest)
            } label: {
                Text("Add Guest")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.xl)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }

    private var loadMoreButton: some View {
        Button {
            // Load more functionality
        } label: {
            Text("Load More Guests")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppColors.textSecondary)
                .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Functions

    private func exportGuestList() {
        AppLogger.ui.info("Export guest list requested")
        showingExportSheet = true
    }
    
    // MARK: - Computed Filtering (Vendor-style)
    
    private var filteredAndSortedGuests: [Guest] {
        let filtered = guestStore.guests.filter { guest in
            // Search across name, email, and phone fields
            let matchesSearch = searchText.isEmpty ||
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                guest.email?.localizedCaseInsensitiveContains(searchText) == true ||
                guest.phone?.contains(searchText) == true
            
            // Filter by RSVP status with grouped logic:
            // - Attending = attending + confirmed
            // - Declined = declined + noResponse
            // - Pending = everything else
            let matchesStatus: Bool
            if let status = selectedStatus {
                switch status {
                case .attending:
                    // Attending includes both attending and confirmed
                    matchesStatus = guest.rsvpStatus == .attending || guest.rsvpStatus == .confirmed
                case .declined:
                    // Declined includes both declined and noResponse
                    matchesStatus = guest.rsvpStatus == .declined || guest.rsvpStatus == .noResponse
                case .pending:
                    // Pending is everything else (not attending, confirmed, declined, or noResponse)
                    matchesStatus = guest.rsvpStatus != .attending && 
                                   guest.rsvpStatus != .confirmed && 
                                   guest.rsvpStatus != .declined && 
                                   guest.rsvpStatus != .noResponse
                default:
                    // For any other status, match exactly
                    matchesStatus = guest.rsvpStatus == status
                }
            } else {
                // No filter selected, show all
                matchesStatus = true
            }
            
            // Filter by which side invited the guest (bride/groom/both)
            let matchesInvitedBy = selectedInvitedBy == nil || guest.invitedBy == selectedInvitedBy
            
            return matchesSearch && matchesStatus && matchesInvitedBy
        }
        
        // Apply sorting
        return selectedSortOption.sort(filtered)
    }
}

// MARK: - Supporting Views

private struct GuestManagementStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let subtitleColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(value)
                        .font(Typography.displayMedium)
                        .foregroundColor(AppColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundColor(subtitleColor)
                    }
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary.opacity(0.2))
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct GuestCardV4: View {
    let guest: Guest
    let settings: CoupleSettings
    @State private var avatarImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Avatar and Status Badge
            ZStack(alignment: .topTrailing) {
                // Avatar Circle with Multiavatar
                Group {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            )
                    }
                }
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.xxl)
                .padding(.leading, Spacing.xxl)

                // Status Badge
                statusBadge
                    .padding(.top, Spacing.xxl)
                    .padding(.trailing, Spacing.xxl)
            }
            .frame(height: 72)

            // Guest Name
Text(guest.fullName)
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.sm)

            // Email
            if let email = guest.email, !email.isEmpty {
            Text(email)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.xs)
            }

            // Invited By
            if let invitedBy = guest.invitedBy {
                Text(invitedBy.displayName(with: settings))
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.sm)
            }

            Spacer()

            // Table and Meal Section
            VStack(spacing: 0) {
                Divider()
                    .background(AppColors.borderLight)

                HStack {
                    Text("Table")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    if let table = guest.tableAssignment {
                        Text("\(table)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textPrimary)
                    } else {
                        Text("-")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.sm)

                Divider()
                    .background(AppColors.borderLight)

                HStack {
                    Text("Meal Choice")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    if let mealOption = guest.mealOption, !mealOption.isEmpty {
                        Text(mealOption)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                    } else {
                        Text("Not selected")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.sm)
            }
        }
        .frame(width: 290, height: 243)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderLight, lineWidth: 0.5)
        )
        .accessibleListItem(
            label: guest.fullName,
            hint: "Tap to view guest details",
            value: guest.rsvpStatus.displayName
        )
    }

    private var statusBadge: some View {
        Group {
            switch guest.rsvpStatus {
            case .confirmed:
                Text("Confirmed")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.success)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.successLight)
                    .cornerRadius(9999)
            case .attending:
                Text("Attending")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.success)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.successLight)
                    .cornerRadius(9999)
            case .pending:
                Text("Pending")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.warning)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.warningLight)
                    .cornerRadius(9999)
            case .maybe:
                Text("Maybe")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.warning)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.warningLight)
                    .cornerRadius(9999)
            case .invited:
                Text("Invited")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.warning)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.warningLight)
                    .cornerRadius(9999)
            case .declined:
                Text("Declined")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.errorLight)
                    .cornerRadius(9999)
            case .noResponse:
                Text("No Response")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.errorLight)
                    .cornerRadius(9999)
            default:
                Text(guest.rsvpStatus.displayName)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.cardBackground)
                    .cornerRadius(9999)
            }
        }
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 96, height: 96) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarJSService
        }
    }
}

private struct GuestFilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .font(Typography.caption)
                .foregroundColor(AppColors.textPrimary)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.pill)
    }
}

struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(AppColors.error)

            Text("Error Loading Guests")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Text(error.localizedDescription)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Text("Try Again")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.xl)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
}

#Preview("Light 900x700") {
    withDependencies {
        let mock = MockGuestRepository()
        mock.guests = PreviewData.sampleGuests
        $0.guestRepository = mock
    } operation: {
        GuestManagementViewV4()
            .environmentObject(AppStores.shared)
            .environmentObject(SettingsStoreV2())
            .environmentObject(AppCoordinator.shared)
            .frame(width: 900, height: 700)
            .preferredColorScheme(.light)
    }
}

#Preview("Dark 1400x900") {
    withDependencies {
        let mock = MockGuestRepository()
        mock.guests = PreviewData.sampleGuests
        $0.guestRepository = mock
    } operation: {
        GuestManagementViewV4()
            .environmentObject(AppStores.shared)
            .environmentObject(SettingsStoreV2())
            .environmentObject(AppCoordinator.shared)
            .frame(width: 1400, height: 900)
            .preferredColorScheme(.dark)
    }
}

private enum PreviewData {
    static let coupleId = UUID()
    static let sampleGuests: [Guest] = [
        makeGuest(first:"Ava", last:"Johnson", email:"ava@example.com", status:.confirmed, invitedBy:.bride1, table:1, meal:"Chicken"),
        makeGuest(first:"Liam", last:"Smith", email:"liam@example.com", status:.pending, invitedBy:.bride2, table:2, meal:"Fish"),
        makeGuest(first:"Mia", last:"Brown", email:"mia@example.com", status:.declined, invitedBy:.both, table:nil, meal:nil),
        makeGuest(first:"Noah", last:"Davis", email:"noah@example.com", status:.invited, invitedBy:.bride1, table:3, meal:"Veg"),
        makeGuest(first:"Emma", last:"Wilson", email:"emma@example.com", status:.attending, invitedBy:.both, table:4, meal:"Steak")
    ]

    private static func makeGuest(first: String, last: String, email: String?, status: RSVPStatus, invitedBy: InvitedBy?, table: Int?, meal: String?) -> Guest {
        Guest(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date(),
            firstName: first,
            lastName: last,
            email: email,
            phone: nil,
            guestGroupId: nil,
            relationshipToCouple: nil,
            invitedBy: invitedBy,
            rsvpStatus: status,
            rsvpDate: nil,
            plusOneAllowed: false,
            plusOneName: nil,
            plusOneAttending: false,
            attendingCeremony: true,
            attendingReception: true,
            attendingOtherEvents: nil,
            dietaryRestrictions: nil,
            accessibilityNeeds: nil,
            tableAssignment: table,
            seatNumber: nil,
            preferredContactMethod: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            invitationNumber: nil,
            isWeddingParty: false,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: coupleId,
            mealOption: meal,
            giftReceived: false,
            notes: nil,
            hairDone: false,
            makeupDone: false
        )
    }
}
