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
    @State private var showingImportSheet = false
    
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
    
    
    private var totalGuests: Int {
        guestStore.guests.count
    }
    
    private var confirmedCount: Int {
        guestStore.guests.filter { $0.rsvpStatus == .confirmed || $0.rsvpStatus == .attending }.count
    }
    
    private var pendingCount: Int {
        guestStore.guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited }.count
    }
    
    private var declinedCount: Int {
        guestStore.guests.filter { $0.rsvpStatus == .declined }.count
    }
    
    private var acceptanceRate: Double {
        guard totalGuests > 0 else { return 0 }
        return Double(confirmedCount) / Double(totalGuests)
    }
    
    private var weeklyChange: Int {
        // Calculate guests added in the last 7 days
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return guestStore.guests.filter { $0.createdAt > weekAgo }.count
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundSecondary
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
        .task {
            if guestStore.loadingState.isIdle {
                await guestStore.loadGuestData()
            }
        }
        .onChange(of: searchText) { newValue in
            guestStore.filterGuests(
                searchText: newValue,
                selectedStatus: selectedStatus,
                selectedInvitedBy: selectedInvitedBy
            )
        }
        .onChange(of: selectedStatus) { _ in
            guestStore.filterGuests(
                searchText: searchText,
                selectedStatus: selectedStatus,
                selectedInvitedBy: selectedInvitedBy
            )
        }
        .onChange(of: selectedInvitedBy) { _ in
            guestStore.filterGuests(
                searchText: searchText,
                selectedStatus: selectedStatus,
                selectedInvitedBy: selectedInvitedBy
            )
        }
        .searchable(text: $searchText, placement: .automatic)
        .toolbar {
            ToolbarItemGroup {
                Picker("RSVP", selection: $selectedStatus) {
                    Text("Any").tag(RSVPStatus?.none)
                    ForEach(RSVPStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(RSVPStatus?.some(status))
                    }
                }
                .pickerStyle(.menu)

                Picker("Invited By", selection: $selectedInvitedBy) {
                    Text("Any").tag(InvitedBy?.none)
                    ForEach(InvitedBy.allCases, id: \.self) { who in
                        Text(who.displayName(with: settings)).tag(InvitedBy?.some(who))
                    }
                }
                .pickerStyle(.menu)
            }
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
        HStack(spacing: Spacing.lg) {
            GuestManagementStatCard(
                title: "Total Guests",
                value: "\(totalGuests)",
                subtitle: weeklyChange > 0 ? "+\(weeklyChange) this week" : nil,
                subtitleColor: AppColors.success,
                icon: "person.3.fill"
            )
            
            GuestManagementStatCard(
                title: "Confirmed",
                value: "\(confirmedCount)",
                subtitle: "\(Int(acceptanceRate * 100))% acceptance",
                subtitleColor: AppColors.success,
                icon: "checkmark.circle.fill"
            )
            
            GuestManagementStatCard(
                title: "Pending",
                value: "\(pendingCount)",
                subtitle: "\(Int(Double(pendingCount) / Double(max(totalGuests, 1)) * 100))% pending",
                subtitleColor: AppColors.warning,
                icon: "clock.fill"
            )
            
            GuestManagementStatCard(
                title: "Declined",
                value: "\(declinedCount)",
                subtitle: "\(Int(Double(declinedCount) / Double(max(totalGuests, 1)) * 100))% declined",
                subtitleColor: AppColors.error,
                icon: "xmark.circle.fill"
            )
        }
    }
    
    // MARK: - Search and Filters Section
    
    private var searchAndFiltersSection: some View {
        // Inline search UI removed in favor of native .searchable & toolbar pickers
        Group {
            if selectedStatus != nil || selectedInvitedBy != nil {
                HStack(spacing: Spacing.sm) {
                    if let status = selectedStatus {
                        GuestFilterChip(
                            title: status.displayName,
                            onRemove: { selectedStatus = nil }
                        )
                    }
                    if let invitedBy = selectedInvitedBy {
                        GuestFilterChip(
                            title: invitedBy.displayName(with: settings),
                            onRemove: { selectedInvitedBy = nil }
                        )
                    }
                    Spacer()
                    Button("Clear Filters") {
                        selectedStatus = nil
                        selectedInvitedBy = nil
                    }
                    .buttonStyle(.plain)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                }
                .padding(Spacing.lg)
                .background(AppColors.cardBackground)
                .cornerRadius(CornerRadius.lg)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
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
            } else if guestStore.filteredGuests.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg)
                ], spacing: Spacing.lg) {
                    ForEach(guestStore.filteredGuests, id: \.id) { guest in
                        GuestCardV4(guest: guest, settings: settings)
                            .onTapGesture {
                                coordinator.present(.editGuest(guest))
                            }
                    }
                }
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
        // Export functionality will be implemented
        AppLogger.ui.info("Export guest list requested")
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
            case .confirmed, .attending:
                Text("Confirmed")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.success)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.successLight)
                    .cornerRadius(9999)
            case .pending, .invited:
                Text("Pending")
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
