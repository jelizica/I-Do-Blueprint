//
//  GuestDashboardViewV2.swift
//  I Do Blueprint
//
//  Guest Management Dashboard matching HTML design with DashboardViewV7 theming
//  Features:
//  - Glassmorphism panels with frosted glass effect
//  - Mesh gradient background matching dashboard
//  - Stats cards: Total Guests, Acceptance Rate, Attending, Pending
//  - Search and filter toolbar
//  - Guest card grid with real Supabase data
//

import SwiftUI

struct GuestDashboardViewV2: View {
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
    @State private var viewMode: ViewMode = .grid
    
    private var settings: CoupleSettings {
        settingsStore.settings
    }
    
    enum ViewMode {
        case grid
        case list
    }
    
    // Adaptive grid for guest cards
    private let guestColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 280), spacing: Spacing.lg, alignment: .top)
    ]
    
    var body: some View {
        ZStack {
            // Background gradient matching DashboardViewV7
            AppGradients.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Stats Cards Section
                    statsCardsSection
                    
                    // Search and Filters Section
                    searchAndFiltersSection
                    
                    // Guest Grid Section
                    guestGridSection
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.huge)
            }
        }
        .navigationTitle("")
        .sheet(isPresented: $showingImportSheet) {
            GuestCSVImportView()
                .environmentObject(guestStore)
        }
        .sheet(isPresented: $showingExportSheet) {
            GuestExportView(
                guests: filteredAndSortedGuests,
                settings: settings,
                onExportSuccessful: handleExportSuccess
            )
        }
        .task {
            if guestStore.loadingState.isIdle {
                await guestStore.loadGuestData()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            // Icon and Title
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Guest Management")
                        .font(Typography.title1)
                        .foregroundColor(SemanticColors.textPrimary)
                    
                    Text("Wedding Planner • \(formattedWeddingDate)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: Spacing.md) {
                Button(action: { showingImportSheet = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                        Text("Import")
                            .font(Typography.bodyRegular)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(GlassButtonStyle())

                Button(action: { showingExportSheet = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("Export")
                            .font(Typography.bodyRegular)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(GlassButtonStyle())
                
                Button(action: { coordinator.present(.addGuest) }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Guest")
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
    
    // MARK: - Stats Cards Section
    
    private var statsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Spacing.lg),
            GridItem(.flexible(), spacing: Spacing.lg),
            GridItem(.flexible(), spacing: Spacing.lg),
            GridItem(.flexible(), spacing: Spacing.lg)
        ], spacing: Spacing.lg) {
            // Total Guests Card
            StatCardV2(
                title: "Total Guests",
                value: "\(guestStore.totalGuestsCount)",
                subtitle: guestStore.weeklyChange > 0 ? "+\(guestStore.weeklyChange) this week" : nil,
                subtitleColor: SemanticColors.success,
                icon: "person.3.fill",
                iconColor: SemanticColors.primaryAction
            )
            
            // Acceptance Rate Card
            StatCardV2(
                title: "Acceptance Rate",
                value: "\(Int(guestStore.acceptanceRate * 100))%",
                subtitle: nil,
                subtitleColor: SemanticColors.success,
                icon: "chart.pie.fill",
                iconColor: SemanticColors.success,
                showProgressBar: true,
                progress: guestStore.acceptanceRate
            )

            // Attending Card
            StatCardV2(
                title: "Attending",
                value: "\(guestStore.attendingCount)",
                subtitle: "Confirmed & Attending",
                subtitleColor: SemanticColors.success,
                icon: "checkmark.circle.fill",
                iconColor: SemanticColors.success
            )
            
            // Pending Card
            StatCardV2(
                title: "Pending",
                value: "\(guestStore.pendingCount)",
                subtitle: "Needs follow up",
                subtitleColor: SemanticColors.warning,
                icon: "hourglass",
                iconColor: SemanticColors.secondaryAction
            )
        }
    }
    
    // MARK: - Search and Filters Section
    
    private var searchAndFiltersSection: some View {
        HStack(spacing: Spacing.lg) {
            // Search Bar
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(SemanticColors.textSecondary)
                    .font(.system(size: 14))
                
                TextField("Search guests by name or email...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Typography.bodyRegular)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .modifier(GlassPanelStyle(cornerRadius: 24, padding: 0))
            .frame(maxWidth: .infinity)
            
            // Filter Controls
            HStack(spacing: Spacing.md) {
                // Status Filter
                Menu {
                    Button("All Guests") {
                        selectedStatus = nil
                    }
                    Divider()
                    ForEach(RSVPStatus.allCases, id: \.self) { status in
                        Button(status.displayName) {
                            selectedStatus = status
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14))
                        Text(selectedStatus?.displayName ?? "All Guests")
                            .font(Typography.bodyRegular)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(GlassButtonStyle())
                
                // Invited By Filter
                Menu {
                    Button("All") {
                        selectedInvitedBy = nil
                    }
                    Divider()
                    ForEach(InvitedBy.allCases, id: \.self) { invitedBy in
                        Button(invitedBy.displayName(with: settings)) {
                            selectedInvitedBy = invitedBy
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                        Text("Invited By: \(selectedInvitedBy?.displayName(with: settings) ?? "All")")
                            .font(Typography.bodyRegular)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(GlassButtonStyle())
                
                // Sort Menu
                Menu {
                    ForEach(GuestSortOption.allCases, id: \.self) { option in
                        Button(option.displayName) {
                            selectedSortOption = option
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                        Text("Sort: \(selectedSortOption.displayName)")
                            .font(Typography.bodyRegular)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(GlassButtonStyle())
                
                // View Toggle
                HStack(spacing: 0) {
                    Button(action: { viewMode = .grid }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                    }
                    .background(viewMode == .grid ? Color.white.opacity(0.3) : Color.clear)
                    .cornerRadius(6)
                    
                    Button(action: { viewMode = .list }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14))
                            .frame(width: 32, height: 32)
                    }
                    .background(viewMode == .list ? Color.white.opacity(0.3) : Color.clear)
                    .cornerRadius(6)
                }
                .padding(4)
                .modifier(GlassPanelStyle(cornerRadius: 8, padding: 0))
            }
        }
    }
    
    // MARK: - Guest Grid Section
    
    private var guestGridSection: some View {
        Group {
            if guestStore.isLoading {
                ProgressView("Loading guests...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = guestStore.error {
                GuestErrorView(error: error) {
                    Task {
                        await guestStore.retryLoad()
                    }
                }
            } else if filteredAndSortedGuests.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: guestColumns, spacing: Spacing.lg) {
                    ForEach(filteredAndSortedGuests) { guest in
                        GuestCardV2(guest: guest, settings: settings)
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
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.textSecondary)
            
            Text("No guests found")
                .font(Typography.title2)
                .foregroundColor(SemanticColors.textPrimary)
            
            Text("Add your first guest to get started")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
            
            Button(action: { coordinator.present(.addGuest) }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus")
                    Text("Add Guest")
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .modifier(GlassPanelStyle())
    }
    
    // MARK: - Helper Properties
    
    private var formattedWeddingDate: String {
        let weddingDate = settings.global.weddingDate
        guard !weddingDate.isEmpty else {
            return "Date TBD"
        }
        return weddingDate
    }
    
    private var filteredAndSortedGuests: [Guest] {
        var guests = guestStore.guests
        
        // Apply search filter
        if !searchText.isEmpty {
            guests = guests.filter { guest in
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                (guest.email?.localizedCaseInsensitiveContains(searchText) ?? false)
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
        
        // Apply sorting
        return selectedSortOption.sort(guests)
    }
    
    private func handleExportSuccess(fileURL: URL, format: GuestExportFormat) {
        NSWorkspace.shared.open(fileURL)
    }
}

// MARK: - Stat Card Component

struct StatCardV2: View {
    let title: String
    let value: String
    let subtitle: String?
    let subtitleColor: Color
    let icon: String
    let iconColor: Color
    var showProgressBar: Bool = false
    var progress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    Text(value)
                        .font(Typography.displayMedium)
                        .foregroundColor(SemanticColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundColor(subtitleColor)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    )
            }
            
            if showProgressBar {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(iconColor)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 132)
        .modifier(GlassPanelStyle(cornerRadius: 16, padding: 0))
    }
}

// MARK: - Guest Card Component

struct GuestCardV2: View {
    let guest: Guest
    let settings: CoupleSettings
    @State private var avatarImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header: Avatar + Status Badge
            HStack(alignment: .top) {
                // Avatar with Multiavatar
                Group {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        initialsAvatar
                    }
                }
                .task {
                    await loadAvatar()
                }
                
                Spacer()
                
                // Status Badge
                Text(guest.rsvpStatus.displayName)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(guest.rsvpStatus.color)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(guest.rsvpStatus.color.opacity(0.15))
                    .cornerRadius(12)
            }
            
            // Guest Info
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.fullName)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                Text(guest.email ?? "No email")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)

                if let invitedBy = guest.invitedBy {
                    Text("Invited by \(invitedBy.displayName(with: settings))")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }
            
            // Footer: Table + Meal Choice
            Divider()
                .background(Color.gray.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TABLE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    Text(guest.tableAssignment.map { "\($0)" } ?? "-")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("MEAL CHOICE")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(guest.mealOption ?? "-")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }
        }
        .padding(Spacing.lg)
        .modifier(GlassPanelStyle(cornerRadius: 16, padding: 0))
    }
    
    private var initialsAvatar: some View {
        let initials = guest.fullName.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
        
        let colors: [Color] = [
            AppColors.Dashboard.noteAction,
            AppColors.primary,
            AppColors.Dashboard.eventAction,
            AppColors.Dashboard.taskAction
        ]
        let colorIndex = abs(guest.fullName.hashValue) % colors.count
        
        return Circle()
            .fill(colors[colorIndex].opacity(0.15))
            .frame(width: 48, height: 48)
            .overlay(
                Text(initials)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colors[colorIndex])
            )
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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

// MARK: - Button Styles

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(SemanticColors.textPrimary)
            .modifier(GlassPanelStyle(cornerRadius: 8, padding: 0))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(AppColors.primary)
            .cornerRadius(8)
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    GuestDashboardViewV2()
        .environmentObject(SettingsStoreV2())
        .environmentObject(AppCoordinator.shared)
        .environment(\.appStores, AppStores.shared)
}
