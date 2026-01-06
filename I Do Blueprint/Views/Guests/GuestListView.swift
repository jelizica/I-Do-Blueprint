//
//  GuestListView.swift
//  I Do Blueprint
//
//  Table-based list view for guest management matching HTML design
//  Features:
//  - Glassmorphism table with frosted glass rows
//  - Sortable column headers
//  - Avatar/initials in first column
//  - Status badges with colors
//  - Hover effects on rows
//  - Scrollable list (no pagination)
//

import SwiftUI

struct GuestListView: View {
    let guests: [Guest]
    let settings: CoupleSettings
    let onGuestTap: (Guest) -> Void
    
    @State private var sortColumn: SortColumn = .name
    @State private var sortAscending: Bool = true
    @State private var hoveredGuestId: UUID?
    
    enum SortColumn {
        case name
        case email
        case invitedBy
        case status
        case table
        case mealChoice
    }
    
    var body: some View {
        // Table Container with glassmorphism styling
        // Header scrolls with content (no pinnedViews) for natural scroll behavior
        VStack(spacing: 0) {
            // Table Header - scrolls with content
            tableHeader
            
            // Table Rows
            LazyVStack(spacing: 0) {
                ForEach(sortedGuests) { guest in
                    tableRow(for: guest)
                        .onTapGesture {
                            onGuestTap(guest)
                        }
                }
            }
        }
        .background(
            ZStack {
                // Base blur layer - glassmorphism effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                // Semi-transparent white overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.25))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
    }
    
    // MARK: - Table Header
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // # Column (Avatar)
            headerCell(title: "#", width: 80, column: nil)
            
            // Guest Name Column
            headerCell(title: "GUEST NAME", width: 200, column: .name)
            
            // Email Column
            headerCell(title: "EMAIL", width: 220, column: .email)
            
            // Invited By Column
            headerCell(title: "INVITED BY", width: 140, column: .invitedBy)
            
            // Status Column
            headerCell(title: "STATUS", width: 140, column: .status, centered: true)
            
            // Table Column
            headerCell(title: "TABLE", width: 100, column: .table, centered: true)
            
            // Meal Choice Column
            headerCell(title: "MEAL CHOICE", width: nil, column: .mealChoice, alignment: .trailing)
            
            // Actions Column
            Spacer()
                .frame(width: 60)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                )
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private func headerCell(
        title: String,
        width: CGFloat?,
        column: SortColumn?,
        centered: Bool = false,
        alignment: HorizontalAlignment = .leading
    ) -> some View {
        Group {
            if let column = column {
                Button(action: {
                    if sortColumn == column {
                        sortAscending.toggle()
                    } else {
                        sortColumn = column
                        sortAscending = true
                    }
                }) {
                    HStack(spacing: Spacing.xs) {
                        Text(title)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(SemanticColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        if sortColumn == column {
                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(SemanticColors.textSecondary)
                        } else {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 8))
                                .foregroundColor(SemanticColors.textTertiary.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: centered ? .center : (alignment == .trailing ? .trailing : .leading))
                }
                .buttonStyle(.plain)
                .frame(width: width)
            } else {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .frame(width: width, alignment: centered ? .center : (alignment == .trailing ? .trailing : .leading))
            }
        }
    }
    
    // MARK: - Table Row
    
    // Fixed row height to prevent LazyVStack layout jumping
    // Avatar (48px) + vertical padding (24px) + buffer for badges = 72px minimum
    private let rowHeight: CGFloat = 72

    private func tableRow(for guest: Guest) -> some View {
        HStack(spacing: 0) {
            // Avatar Column
            avatarCell(for: guest)
                .frame(width: 80)

            // Guest Name Column
            Text(guest.fullName)
                .font(Typography.bodyRegular)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)
                .frame(width: 200, alignment: .leading)
                .lineLimit(1)

            // Email Column
            Text(guest.email ?? "No email")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 220, alignment: .leading)
                .lineLimit(1)

            // Invited By Column
            invitedByBadge(for: guest)
                .frame(width: 140, height: rowHeight, alignment: .leading)

            // Status Column
            statusBadge(for: guest)
                .frame(width: 140, height: rowHeight, alignment: .center)

            // Table Column
            Text(guest.tableAssignment.map { "\($0)" } ?? "-")
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(guest.tableAssignment != nil ? SemanticColors.textPrimary : SemanticColors.textTertiary)
                .frame(width: 100, alignment: .center)

            // Meal Choice Column
            Text(guest.mealOption ?? "-")
                .font(Typography.bodyRegular)
                .foregroundColor(guest.mealOption != nil ? SemanticColors.textPrimary : SemanticColors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Actions Column
            Button(action: {
                onGuestTap(guest)
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textTertiary)
                    .rotationEffect(.degrees(90))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .opacity(hoveredGuestId == guest.id ? 1.0 : 0.0)
            .frame(width: 60)
        }
        .frame(height: rowHeight)
        .padding(.horizontal, Spacing.lg)
        .background(
            Rectangle()
                .fill(hoveredGuestId == guest.id ? Color.white.opacity(0.35) : Color.white.opacity(0.15))
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredGuestId = hovering ? guest.id : nil
            }
        }
    }
    
    // MARK: - Cell Components
    
    private func avatarCell(for guest: Guest) -> some View {
        GuestListAvatarView(guest: guest, size: 48)
            .padding(.trailing, Spacing.sm)
    }
    
    private func invitedByBadge(for guest: Guest) -> some View {
        Group {
            if let invitedBy = guest.invitedBy {
                let displayName = invitedBy.displayName(with: settings)
                let badgeColor = invitedBy == .bride1 ? AppColors.primary : (invitedBy == .bride2 ? AppColors.Dashboard.eventAction : AppColors.Dashboard.taskAction)
                
                Text(displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(badgeColor.opacity(0.3), lineWidth: 1)
                    )
            } else {
                Text("-")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textTertiary)
            }
        }
    }
    
    private func statusBadge(for guest: Guest) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(guest.rsvpStatus.color)
                .frame(width: 6, height: 6)
            
            Text(guest.rsvpStatus.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(guest.rsvpStatus.color)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(guest.rsvpStatus.color.opacity(0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(guest.rsvpStatus.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: guest.rsvpStatus.color.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    
    private var sortedGuests: [Guest] {
        let sorted = guests.sorted { guest1, guest2 in
            let result: Bool
            switch sortColumn {
            case .name:
                result = guest1.fullName.localizedCaseInsensitiveCompare(guest2.fullName) == .orderedAscending
            case .email:
                let email1 = guest1.email ?? ""
                let email2 = guest2.email ?? ""
                result = email1.localizedCaseInsensitiveCompare(email2) == .orderedAscending
            case .invitedBy:
                let invitedBy1 = guest1.invitedBy?.displayName(with: settings) ?? ""
                let invitedBy2 = guest2.invitedBy?.displayName(with: settings) ?? ""
                result = invitedBy1.localizedCaseInsensitiveCompare(invitedBy2) == .orderedAscending
            case .status:
                result = guest1.rsvpStatus.displayName.localizedCaseInsensitiveCompare(guest2.rsvpStatus.displayName) == .orderedAscending
            case .table:
                switch (guest1.tableAssignment, guest2.tableAssignment) {
                case (.some(let t1), .some(let t2)):
                    result = t1 < t2
                case (.some, .none):
                    result = true
                case (.none, .some):
                    result = false
                case (.none, .none):
                    result = guest1.fullName.localizedCaseInsensitiveCompare(guest2.fullName) == .orderedAscending
                }
            case .mealChoice:
                let meal1 = guest1.mealOption ?? ""
                let meal2 = guest2.mealOption ?? ""
                result = meal1.localizedCaseInsensitiveCompare(meal2) == .orderedAscending
            }
            return sortAscending ? result : !result
        }
        return sorted
    }
}

// MARK: - Guest List Avatar View Component

struct GuestListAvatarView: View {
    let guest: Guest
    let size: CGFloat
    @State private var avatarImage: NSImage?
    @State private var hasLoadedAvatar = false

    var body: some View {
        // Fixed-size container prevents layout shifts during async avatar load
        // The container MUST have explicit frame before any conditional content
        ZStack {
            if let image = avatarImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                initialsAvatar
            }
        }
        .frame(width: size, height: size) // Fixed frame on container, not children
        .task(id: guest.id) {
            // Only load once per guest - prevents re-triggering on scroll
            guard !hasLoadedAvatar else { return }
            hasLoadedAvatar = true
            await loadAvatar()
        }
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

        // No explicit frame here - parent ZStack has fixed frame
        return Circle()
            .fill(colors[colorIndex].opacity(0.15))
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.375, weight: .bold))
                    .foregroundColor(colors[colorIndex])
            )
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: size * 2, height: size * 2) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleGuests = [
        Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah.johnson@email.com",
            phone: "+1 555-123-4567",
            guestGroupId: nil,
            relationshipToCouple: "Friend",
            invitedBy: .bride1,
            rsvpStatus: .confirmed,
            rsvpDate: Date(),
            plusOneAllowed: true,
            plusOneName: "John Smith",
            plusOneAttending: true,
            attendingCeremony: true,
            attendingReception: true,
            attendingRehearsal: false,
            attendingOtherEvents: nil,
            dietaryRestrictions: nil,
            accessibilityNeeds: nil,
            tableAssignment: 5,
            seatNumber: 1,
            preferredContactMethod: .email,
            addressLine1: "123 Main St",
            addressLine2: nil,
            city: "Seattle",
            state: "WA",
            zipCode: "98101",
            country: "USA",
            invitationNumber: "A001",
            isWeddingParty: true,
            weddingPartyRole: "Maid of Honor",
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: "Chicken",
            giftReceived: true,
            notes: nil,
            hairDone: false,
            makeupDone: false
        ),
        Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Michael",
            lastName: "Chen",
            email: "michael.chen@email.com",
            phone: nil,
            guestGroupId: nil,
            relationshipToCouple: "Colleague",
            invitedBy: .bride2,
            rsvpStatus: .pending,
            rsvpDate: nil,
            plusOneAllowed: false,
            plusOneName: nil,
            plusOneAttending: false,
            attendingCeremony: true,
            attendingReception: true,
            attendingRehearsal: false,
            attendingOtherEvents: nil,
            dietaryRestrictions: "Vegetarian",
            accessibilityNeeds: nil,
            tableAssignment: nil,
            seatNumber: nil,
            preferredContactMethod: .email,
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
            coupleId: UUID(),
            mealOption: "Vegetarian",
            giftReceived: false,
            notes: nil,
            hairDone: false,
            makeupDone: false
        ),
        Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Emily",
            lastName: "Davis",
            email: "emily.d@email.com",
            phone: "+1 555-987-6543",
            guestGroupId: nil,
            relationshipToCouple: "Family",
            invitedBy: .both,
            rsvpStatus: .declined,
            rsvpDate: Date(),
            plusOneAllowed: true,
            plusOneName: nil,
            plusOneAttending: false,
            attendingCeremony: false,
            attendingReception: false,
            attendingRehearsal: false,
            attendingOtherEvents: nil,
            dietaryRestrictions: nil,
            accessibilityNeeds: nil,
            tableAssignment: nil,
            seatNumber: nil,
            preferredContactMethod: .phone,
            addressLine1: "456 Oak Ave",
            addressLine2: "Apt 2B",
            city: "Portland",
            state: "OR",
            zipCode: "97201",
            country: "USA",
            invitationNumber: "A003",
            isWeddingParty: false,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: nil,
            giftReceived: false,
            notes: "Unable to attend due to prior commitment",
            hairDone: false,
            makeupDone: false
        )
    ]

    return ZStack {
        MeshGradientBackgroundV7()
            .ignoresSafeArea()

        GuestListView(
            guests: sampleGuests,
            settings: .default,
            onGuestTap: { _ in }
        )
        .padding(Spacing.xxl)
    }
}
