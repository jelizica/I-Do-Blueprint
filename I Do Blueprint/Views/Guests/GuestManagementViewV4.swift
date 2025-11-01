//
//  GuestManagementViewV4.swift
//  I Do Blueprint
//
//  Modern guest management view with Supabase integration
//

import SwiftUI

struct GuestManagementViewV4: View {
    @Environment(\.appStores) private var appStores
    @Environment(\.guestStore) private var guestStore
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator
    
    @State private var searchText = ""
    @State private var selectedStatus: RSVPStatus?
    @State private var selectedInvitedBy: InvitedBy?
    @State private var showingFilters = false
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
    
    private var filteredGuests: [Guest] {
        var guests = guestStore.guests
        
        // Apply search filter
        if !searchText.isEmpty {
            guests = guests.filter { guest in
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                guest.email?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply status filter
        if let status = selectedStatus {
            guests = guests.filter { $0.rsvpStatus == status }
        }
        
        // Apply invited by filter
        if let invitedBy = selectedInvitedBy {
            guests = guests.filter { $0.invitedBy == invitedBy }
        }
        
        return guests
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
            Color(red: 0.98, green: 0.98, blue: 0.99)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Sticky Header Section
                headerSection
                    .padding(.horizontal, 40)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                
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
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
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
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 0) {
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Guest Management")
                    .font(.custom("Roboto", size: 30).weight(.bold))
                    .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
                
                Text("Manage and track all your guests in one place")
                    .font(.custom("Roboto", size: 16))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
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
                            .font(.custom("Roboto", size: 15.45))
                    }
                    .foregroundColor(Color(red: 0.22, green: 0.25, blue: 0.32))
                    .frame(height: 42)
                    .padding(.horizontal, 16)
                    .background(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.5)
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
                            .font(.custom("Roboto", size: 16))
                    }
                    .foregroundColor(Color(red: 0.22, green: 0.25, blue: 0.32))
                    .frame(height: 42)
                    .padding(.horizontal, 16)
                    .background(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.5)
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
                            .font(.custom("Roboto", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(height: 42)
                    .padding(.horizontal, 20)
                    .background(Color(red: 0.15, green: 0.39, blue: 0.92))
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
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                // Search Field
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textTertiary)
                    
                    TextField("Search guests...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(Typography.bodyRegular)
                }
                .padding(Spacing.md)
                .background(.white)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(AppColors.borderLight, lineWidth: 1)
                )
                
                // Status Filter
                if let status = selectedStatus {
                    GuestFilterChip(
                        title: status.displayName,
                        onRemove: { selectedStatus = nil }
                    )
                }
                
                // Invited By Filter
                if let invitedBy = selectedInvitedBy {
                    GuestFilterChip(
                        title: invitedBy.displayName(with: settings),
                        onRemove: { selectedInvitedBy = nil }
                    )
                }
                
                Spacer()
                
                // More Filters Button
                Button {
                    showingFilters.toggle()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("More Filters")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(.plain)
                
                // Send Invites Button
                Button {
                    // Send invites functionality
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "envelope.fill")
                        Text("Send Invites")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
            
            // Filter Options (when expanded)
            if showingFilters {
                filterOptionsView
            }
        }
        .padding(Spacing.lg)
        .background(.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var filterOptionsView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Filter by Status")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(RSVPStatus.allCases, id: \.self) { status in
                        Button {
                            selectedStatus = selectedStatus == status ? nil : status
                        } label: {
                            Text(status.displayName)
                                .font(Typography.caption)
                                .foregroundColor(selectedStatus == status ? .white : AppColors.textSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(selectedStatus == status ? AppColors.primary : AppColors.cardBackground)
                                .cornerRadius(CornerRadius.pill)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Text("Filter by Invited By")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
                .padding(.top, Spacing.sm)
            
            HStack(spacing: Spacing.sm) {
                ForEach(InvitedBy.allCases, id: \.self) { invitedBy in
                    Button {
                        selectedInvitedBy = selectedInvitedBy == invitedBy ? nil : invitedBy
                    } label: {
                        Text(invitedBy.displayName(with: settings))
                            .font(Typography.caption)
                            .foregroundColor(selectedInvitedBy == invitedBy ? .white : AppColors.textSecondary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedInvitedBy == invitedBy ? AppColors.primary : AppColors.cardBackground)
                            .cornerRadius(CornerRadius.pill)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
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
            } else if filteredGuests.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg),
                    GridItem(.flexible(), spacing: Spacing.lg)
                ], spacing: Spacing.lg) {
                    ForEach(filteredGuests, id: \.id) { guest in
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
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.xl)
        .background(.white)
        .cornerRadius(CornerRadius.lg)
    }
    
    private var loadMoreButton: some View {
        Button {
            // Load more functionality
        } label: {
            Text("Load More Guests")
                .font(Typography.bodyRegular)
                .foregroundColor(.white)
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
        .background(.white)
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
                            .fill(Color(red: 0.90, green: 0.91, blue: 0.92))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(red: 0.60, green: 0.62, blue: 0.65))
                            )
                    }
                }
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.leading, 24)
                
                // Status Badge
                statusBadge
                    .padding(.top, 24)
                    .padding(.trailing, 24)
            }
            .frame(height: 72)
            
            // Guest Name
            Text(guest.fullName)
                .font(.custom("Roboto", size: 18).weight(.semibold))
                .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
                .lineLimit(1)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            
            // Email
            if let email = guest.email, !email.isEmpty {
                Text(email)
                    .font(.custom("Roboto", size: 13.78))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
                    .lineLimit(1)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }
            
            // Invited By
            if let invitedBy = guest.invitedBy {
                Text(invitedBy.displayName(with: settings))
                    .font(.custom("Roboto", size: 12))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Table and Meal Section
            VStack(spacing: 0) {
                Divider()
                    .background(Color(red: 0.95, green: 0.96, blue: 0.96))
                
                HStack {
                    Text("Table")
                        .font(.custom("Roboto", size: 13.90))
                        .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    
                    Spacer()
                    
                    if let table = guest.tableAssignment {
                        Text("\(table)")
                            .font(.custom("Roboto", size: 13.90))
                            .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
                    } else {
                        Text("-")
                            .font(.custom("Roboto", size: 13.90))
                            .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                
                Divider()
                    .background(Color(red: 0.95, green: 0.96, blue: 0.96))
                
                HStack {
                    Text("Meal Choice")
                        .font(.custom("Roboto", size: 13.90))
                        .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    
                    Spacer()
                    
                    if let mealOption = guest.mealOption, !mealOption.isEmpty {
                        Text(mealOption)
                            .font(.custom("Roboto", size: 13.90))
                            .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
                            .lineLimit(1)
                    } else {
                        Text("Not selected")
                            .font(.custom("Roboto", size: 13.90))
                            .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 290, height: 243)
        .background(.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.90, green: 0.91, blue: 0.92), lineWidth: 0.5)
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
                    .font(.custom("Roboto", size: 12).weight(.medium))
                    .foregroundColor(Color(red: 0.09, green: 0.40, blue: 0.20))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.86, green: 0.99, blue: 0.91))
                    .cornerRadius(9999)
            case .pending, .invited:
                Text("Pending")
                    .font(.custom("Roboto", size: 12).weight(.medium))
                    .foregroundColor(Color(red: 0.57, green: 0.25, blue: 0.05))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1, green: 0.95, blue: 0.78))
                    .cornerRadius(9999)
            case .declined:
                Text("Declined")
                    .font(.custom("Roboto", size: 12).weight(.medium))
                    .foregroundColor(Color(red: 0.60, green: 0.11, blue: 0.11))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1, green: 0.89, blue: 0.89))
                    .cornerRadius(9999)
            default:
                Text(guest.rsvpStatus.displayName)
                    .font(.custom("Roboto", size: 12).weight(.medium))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.95, green: 0.96, blue: 0.96))
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
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.xl)
        .background(.white)
        .cornerRadius(CornerRadius.lg)
    }
}

#Preview {
    GuestManagementViewV4()
        .environmentObject(AppStores.shared)
        .environmentObject(SettingsStoreV2())
        .environmentObject(AppCoordinator.shared)
}
