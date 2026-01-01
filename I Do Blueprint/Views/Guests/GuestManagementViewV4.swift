//
//  GuestManagementViewV4.swift
//  I Do Blueprint
//
//  Modern guest management view with Supabase integration
//  Refactored to reduce nesting and improve maintainability
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
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
            // Calculate available width for content (geometry width minus padding on both sides)
            let availableWidth = geometry.size.width - (horizontalPadding * 2)

            ZStack {
                AppGradients.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Sticky Header Section
                    GuestManagementHeader(
                        windowSize: windowSize,
                        onImport: { showingImportSheet = true },
                        onExport: exportGuestList,
                        onAddGuest: { coordinator.present(.addGuest) }
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                    .padding(.bottom, Spacing.lg)

                    // Scrollable Content Section
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Stats Cards
                            GuestStatsSection(
                                windowSize: windowSize,
                                totalGuestsCount: guestStore.totalGuestsCount,
                                weeklyChange: guestStore.weeklyChange,
                                acceptanceRate: guestStore.acceptanceRate,
                                attendingCount: guestStore.attendingCount,
                                pendingCount: guestStore.pendingCount,
                                declinedCount: guestStore.declinedCount
                            )

                            // Search and Filters
                            GuestSearchAndFilters(
                                windowSize: windowSize,
                                searchText: $searchText,
                                selectedStatus: $selectedStatus,
                                selectedInvitedBy: $selectedInvitedBy,
                                selectedSortOption: $selectedSortOption,
                                settings: settings
                            )

                            // Guest List
                            guestListContent(windowSize: windowSize)
                        }
                        // Constrain the VStack to the available width to prevent overflow
                        .frame(width: availableWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, windowSize == .compact ? Spacing.lg : Spacing.huge)
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
                    onExportSuccessful: handleExportSuccess
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
    }

    // MARK: - Guest List Content

    @ViewBuilder
    private func guestListContent(windowSize: WindowSize) -> some View {
        if guestStore.isLoading {
            ProgressView("Loading guests...")
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if let error = guestStore.error {
            GuestErrorView(error: error) {
                Task {
                    await guestStore.retryLoad()
                }
            }
        } else {
            GuestListGrid(
                windowSize: windowSize,
                guests: filteredAndSortedGuests,
                settings: settings,
                renderId: guestListRenderId,
                onGuestTap: { guest in
                    coordinator.present(.editGuest(guest))
                },
                onAddGuest: {
                    coordinator.present(.addGuest)
                }
            )
        }
    }

    // MARK: - Helper Functions

    private func exportGuestList() {
        AppLogger.ui.info("Export guest list requested")
        showingExportSheet = true
    }
    
    private func handleExportSuccess(fileURL: URL, format: GuestExportFormat) {
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
    
    // MARK: - Computed Filtering
    
    private var filteredAndSortedGuests: [Guest] {
        let filtered = guestStore.guests.filter { guest in
            // Search across name, email, and phone fields
            let matchesSearch = searchText.isEmpty ||
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                guest.email?.localizedCaseInsensitiveContains(searchText) == true ||
                guest.phone?.contains(searchText) == true
            
            // Filter by RSVP status with grouped logic
            let matchesStatus = filterByStatus(guest)
            
            // Filter by which side invited the guest (bride/groom/both)
            let matchesInvitedBy = selectedInvitedBy == nil || guest.invitedBy == selectedInvitedBy
            
            return matchesSearch && matchesStatus && matchesInvitedBy
        }
        
        // Apply sorting
        return selectedSortOption.sort(filtered)
    }
    
    private func filterByStatus(_ guest: Guest) -> Bool {
        guard let status = selectedStatus else {
            return true // No filter selected, show all
        }
        
        switch status {
        case .attending:
            // Attending includes both attending and confirmed
            return guest.rsvpStatus == .attending || guest.rsvpStatus == .confirmed
        case .declined:
            // Declined includes both declined and noResponse
            return guest.rsvpStatus == .declined || guest.rsvpStatus == .noResponse
        case .pending:
            // Pending is everything else
            return guest.rsvpStatus != .attending && 
                   guest.rsvpStatus != .confirmed && 
                   guest.rsvpStatus != .declined && 
                   guest.rsvpStatus != .noResponse
        default:
            // For any other status, match exactly
            return guest.rsvpStatus == status
        }
    }
}

// MARK: - Preview

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

// MARK: - Preview Data

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
            attendingRehearsal: true,
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
