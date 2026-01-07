//
//  GeneralDashboardViewV1.swift
//  I Do Blueprint
//
//  Created by Claude on 1/7/26.
//  General wedding dashboard with comprehensive overview of all planning areas
//

import SwiftUI
import Charts

// MARK: - Main View

/// General Dashboard V1 - Comprehensive wedding planning overview
/// Displays countdown, RSVP status, tasks, timeline, seating, vendors, and financial info
struct GeneralDashboardViewV1: View {
    // MARK: - Environment

    @Environment(\.appStores) private var appStores
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator

    // MARK: - Stores

    private var guestStore: GuestStoreV2 { appStores.guest }
    private var taskStore: TaskStoreV2 { appStores.task }
    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var timelineStore: TimelineStoreV2 { appStores.timeline }

    // MARK: - State

    @State private var isLoading = true
    @State private var daysUntilWedding: Int = 47
    @State private var overallReadiness: Double = 0.78

    // MARK: - Computed Properties

    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: settingsStore.settings)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            MeshGradientBackgroundV7()
                .ignoresSafeArea()

            // Main content
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    // Header with countdown and readiness
                    headerSection

                    // Main content grid
                    mainContentGrid

                    // Special Attention section
                    specialAttentionSection

                    // Financial Planning section
                    financialPlanningSection

                    // Category Priorities section
                    categoryPrioritiesSection

                    // Bottom 2-column: Needs Approval + Recent Transactions
                    HStack(alignment: .top, spacing: Spacing.lg) {
                        needsApprovalSection
                        recentTransactionsSection
                    }
                }
                .padding(Spacing.xxl)
            }
        }
        .task {
            await loadDashboardData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: Spacing.xxl) {
            // Countdown and couple info (left side)
            countdownCard

            Spacer()

            // Overall Readiness (right side)
            readinessCard
        }
    }

    private var countdownCard: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Heart icon in rounded container
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(SemanticColors.backgroundPrimary)
                .frame(width: 64, height: 64)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(BlushPink.base)
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Days countdown
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text("\(daysUntilWedding)")
                        .font(Typography.displayMedium)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("Days to Go")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                // Couple names
                Text(coupleNames)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                // Wedding date
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textTertiary)

                    Text(formattedWeddingDate)
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
    }

    private var readinessCard: some View {
        HStack(spacing: Spacing.lg) {
            // Conic gradient progress ring
            readinessRing

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Overall Readiness")
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(readinessMessage)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(SemanticColors.backgroundPrimary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderPrimaryLight, lineWidth: 1)
        )
    }

    /// Conic gradient progress ring matching HTML design
    private var readinessRing: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(SemanticColors.borderPrimaryLight, lineWidth: 6)
                .frame(width: 64, height: 64)

            // Progress arc using conic gradient effect
            Circle()
                .trim(from: 0, to: overallReadiness)
                .stroke(
                    SemanticColors.primaryAction,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))

            // Center percentage
            Text("\(Int(overallReadiness * 100))%")
                .font(Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)
        }
    }

    /// Couple names from settings
    private var coupleNames: String {
        let partner1 = settingsStore.settings.global.partner1FullName
        let partner2 = settingsStore.settings.global.partner2FullName

        if !partner1.isEmpty && !partner2.isEmpty {
            return "\(partner1) & \(partner2)"
        } else if !partner1.isEmpty {
            return partner1
        } else if !partner2.isEmpty {
            return partner2
        }
        return "Your Wedding"
    }

    /// Formatted wedding date from settings
    private var formattedWeddingDate: String {
        let weddingDateString = settingsStore.settings.global.weddingDate
        if let weddingDate = DateFormatting.parseDateFromDatabase(weddingDateString) {
            return DateFormatting.formatDateLong(weddingDate, timezone: userTimezone)
        }
        return "Date not set"
    }

    /// Readiness message based on percentage
    private var readinessMessage: String {
        switch overallReadiness {
        case 0..<0.25:
            return "Just getting started!"
        case 0.25..<0.50:
            return "Making progress!"
        case 0.50..<0.75:
            return "Looking good!"
        case 0.75..<0.90:
            return "You're on track!"
        default:
            return "Almost there!"
        }
    }

    // MARK: - Main Content Grid

    /// 3-column layout matching HTML design
    private var mainContentGrid: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Column 1: Guest RSVPs + Seating Progress
            VStack(spacing: Spacing.lg) {
                guestRSVPsCard
                seatingProgressCard
            }
            .frame(maxWidth: .infinity)

            // Column 2: Planning Tasks + Vendor Status
            VStack(spacing: Spacing.lg) {
                planningTasksCard
                vendorStatusCard
            }
            .frame(maxWidth: .infinity)

            // Column 3: Event Timeline + Special Attention (compact)
            VStack(spacing: Spacing.lg) {
                eventTimelineCard
                specialAttentionCompactCard
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Guest RSVPs Card

    private var guestRSVPsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header with more options button
            HStack {
                cardHeader(
                    icon: "envelope.fill",
                    title: "Guest RSVPs",
                    iconColor: SemanticColors.textTertiary
                )

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            // Donut Chart centered
            guestRSVPDonutChart

            // Legend
            guestRSVPLegend

            // Follow-up link
            if needsFollowUpCount > 0 {
                Divider()
                    .background(SemanticColors.borderPrimaryLight)

                Button(action: { coordinator.navigate(to: .guests) }) {
                    HStack(spacing: Spacing.xs) {
                        Text("\(needsFollowUpCount) need follow-up")
                            .font(Typography.bodySmall)
                            .fontWeight(.medium)
                            .foregroundColor(SemanticColors.statusWarning)

                        Image(systemName: "arrow.forward")
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.statusWarning)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    /// Count of guests needing follow-up (pending/invited RSVP status)
    private var needsFollowUpCount: Int {
        guestStore.guests.filter {
            $0.rsvpStatus == .pending || $0.rsvpStatus == .invited
        }.count
    }

    private var guestRSVPDonutChart: some View {
        let guests = guestStore.guests
        let attending = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let awaiting = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited || $0.rsvpStatus == .maybe }.count
        let declined = guests.filter { $0.rsvpStatus == .declined }.count
        let total = guests.count

        return VStack(spacing: Spacing.lg) {
            // Donut chart centered
            ZStack {
                if #available(macOS 13.0, *) {
                    Chart {
                        SectorMark(
                            angle: .value("Attending", attending),
                            innerRadius: .ratio(0.65),
                            angularInset: 1
                        )
                        .foregroundStyle(SemanticColors.statusSuccess)

                        SectorMark(
                            angle: .value("Declined", declined),
                            innerRadius: .ratio(0.65),
                            angularInset: 1
                        )
                        .foregroundStyle(SemanticColors.textTertiary)

                        SectorMark(
                            angle: .value("Awaiting", awaiting),
                            innerRadius: .ratio(0.65),
                            angularInset: 1
                        )
                        .foregroundStyle(SemanticColors.statusWarning)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 160, height: 160)
                }

                // Center label
                VStack(spacing: Spacing.xxs) {
                    Text("\(total)")
                        .font(Typography.numberLarge)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("Invited")
                        .font(Typography.caption2)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private var guestRSVPLegend: some View {
        let guests = guestStore.guests
        let attending = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let awaiting = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited || $0.rsvpStatus == .maybe }.count
        let declined = guests.filter { $0.rsvpStatus == .declined }.count

        return HStack(spacing: Spacing.lg) {
            legendItem(color: SemanticColors.statusSuccess, label: "Attending", count: attending)
            legendItem(color: SemanticColors.statusWarning, label: "Awaiting", count: awaiting)
            legendItem(color: SemanticColors.textTertiary, label: "Declined", count: declined)
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text("\(label) (\(count))")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    // MARK: - Planning Tasks Card

    private var planningTasksCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header with add button
            HStack {
                cardHeader(
                    icon: "checkmark.circle",
                    title: "Planning Tasks",
                    iconColor: SemanticColors.textTertiary
                )

                Spacer()

                // Add task button
                Button(action: { coordinator.navigate(to: .timeline) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.textTertiary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(SemanticColors.backgroundSecondary))
                }
                .buttonStyle(.plain)
            }

            // Task list with checkbox UI
            taskList

            // Footer with remaining and overdue count
            Divider()
                .background(SemanticColors.borderPrimaryLight)

            taskFooter
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var taskList: some View {
        let upcomingTasks = Array(taskStore.tasks
            .filter { $0.status != .completed && $0.status != .cancelled }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(4))

        return VStack(spacing: Spacing.sm) {
            if upcomingTasks.isEmpty {
                emptyTasksView
            } else {
                ForEach(upcomingTasks) { task in
                    taskRow(task)
                }
            }
        }
    }

    private var emptyTasksView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(SemanticColors.textTertiary)

            Text("No upcoming tasks")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    private func taskRow(_ task: WeddingTask) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Checkbox icon (unfilled square)
            Image(systemName: "square")
                .font(.system(size: 20))
                .foregroundColor(SemanticColors.textTertiary)
                .padding(.top, 2)

            // Task info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(task.taskName)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                if let dueDate = task.dueDate {
                    Text("Due in \(dueDateText(dueDate))")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()

            // Priority badge (HIGH/MED style)
            taskPriorityBadge(task.priority)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovered in
            // Visual feedback on hover handled by SwiftUI
        }
    }

    /// Format due date as "X days" text
    private func dueDateText(_ date: Date) -> String {
        let days = DateFormatting.daysBetween(from: Date(), to: date, in: userTimezone)
        if days == 0 {
            return "today"
        } else if days == 1 {
            return "1 day"
        } else if days < 0 {
            return "\(abs(days)) days ago"
        }
        return "\(days) days"
    }

    private var taskFooter: some View {
        let totalRemaining = taskStore.tasks.filter { $0.status != .completed && $0.status != .cancelled }.count
        let overdueTasks = taskStore.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return task.status != .completed && task.status != .cancelled && dueDate < Date()
        }.count

        return HStack {
            Text("\(totalRemaining) tasks remaining")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            Spacer()

            if overdueTasks > 0 {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(BlushPink.base)
                        .frame(width: 6, height: 6)

                    Text("\(overdueTasks) overdue")
                        .font(Typography.caption)
                        .foregroundColor(BlushPink.base)
                }
            }
        }
    }

    private func taskPriorityColor(_ priority: WeddingTaskPriority) -> Color {
        switch priority {
        case .urgent, .high:
            return BlushPink.base
        case .medium:
            return SemanticColors.statusWarning
        case .low:
            return SemanticColors.textTertiary
        }
    }

    private func taskPriorityBadge(_ priority: WeddingTaskPriority) -> some View {
        let (text, bgColor, textColor) = taskPriorityStyle(priority)

        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(bgColor)
            .foregroundColor(textColor)
            .clipShape(Capsule())
    }

    private func taskPriorityStyle(_ priority: WeddingTaskPriority) -> (String, Color, Color) {
        switch priority {
        case .urgent, .high:
            return ("High", BlushPink.background, BlushPink.hover)
        case .medium:
            return ("Med", SemanticColors.statusWarning.opacity(0.15), SemanticColors.statusWarning)
        case .low:
            return ("Low", SemanticColors.backgroundSecondary, SemanticColors.textSecondary)
        }
    }

    // MARK: - Event Timeline Card

    private var eventTimelineCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header with event count badge
            HStack {
                cardHeader(
                    icon: "clock",
                    title: "Event Timeline",
                    iconColor: SemanticColors.textTertiary
                )

                Spacer()

                // Event count badge
                let eventCount = timelineStore.weddingDayEvents.count
                Text("\(eventCount) Planned")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(SemanticColors.statusSuccess)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(SemanticColors.statusSuccess.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Timeline with vertical connector
            eventTimeline
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var eventTimeline: some View {
        let events = Array(timelineStore.weddingDayEvents
            .sorted { ($0.startTime ?? $0.eventDate) < ($1.startTime ?? $1.eventDate) }
            .prefix(4))

        return VStack(alignment: .leading, spacing: 0) {
            if events.isEmpty {
                emptyTimelineView
            } else {
                // Container with vertical line
                ZStack(alignment: .topLeading) {
                    // Vertical connector line
                    Rectangle()
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(width: 2)
                        .padding(.leading, 11) // Center under the circles (24/2 - 1)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.lg)

                    // Events
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                            timelineEventRow(event, isLast: index == events.count - 1, isConfirmed: event.isConfirmed)
                        }
                    }
                }
            }
        }
    }

    private var emptyTimelineView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(SemanticColors.textTertiary)

            Text("No events scheduled")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    private func timelineEventRow(_ event: WeddingDayEvent, isLast: Bool, isConfirmed: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Circle indicator with checkmark or pending icon
            ZStack {
                Circle()
                    .fill(isConfirmed ? SemanticColors.statusSuccess : SemanticColors.statusWarning)
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                Image(systemName: isConfirmed ? "checkmark" : "ellipsis")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }

            // Event info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Time and name row
                HStack(spacing: Spacing.sm) {
                    if let startTime = event.startTime {
                        Text(DateFormatting.formatTime(startTime, timezone: userTimezone).uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(SemanticColors.textTertiary)
                    }

                    Text(event.eventName)
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(isConfirmed ? SemanticColors.textPrimary : SemanticColors.textPrimary.opacity(0.6))
                }

                // Location or status
                if let venue = event.venueName, !venue.isEmpty {
                    Text(venue)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                } else if !isConfirmed {
                    Text("Pending location")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.statusWarning)
                }
            }

            Spacer()
        }
    }

    private func eventCategoryColor(_ category: WeddingDayEventCategory) -> Color {
        switch category {
        case .ceremony: return SemanticColors.statusSuccess
        case .reception: return SemanticColors.statusInfo
        case .photos: return SemanticColors.statusWarning
        case .bridalPrep, .groomPrep: return SoftLavender.base
        case .cocktail, .dinner: return SemanticColors.statusWarning
        case .dancing, .other: return SemanticColors.textSecondary
        }
    }

    // MARK: - Seating Progress Card

    private var seatingProgressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header with percentage
            HStack {
                cardHeader(
                    icon: "chair.fill",
                    title: "Seating Progress",
                    iconColor: SemanticColors.textTertiary
                )

                Spacer()

                Text("\(seatingProgressPercentage)%")
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.primaryAction)
            }

            // Progress bar
            seatingProgressBar

            // Stats text
            Text("\(seatedGuestsCount) of \(attendingGuestsCount) guests seated")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            // Warning about dietary needs if applicable
            if unseatedDietaryCount > 0 {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.statusWarning)

                    Text("\(unseatedDietaryCount) guests with dietary needs unseated. Assign them soon.")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.statusWarning)
                        .lineLimit(2)
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.statusWarning.opacity(0.1))
                )
            }
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var seatingProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(SemanticColors.borderPrimaryLight)
                    .frame(height: 10)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(SemanticColors.primaryAction)
                    .frame(width: geometry.size.width * CGFloat(seatingProgressPercentage) / 100, height: 10)
            }
        }
        .frame(height: 10)
    }

    private var seatingProgressPercentage: Int {
        let total = attendingGuestsCount
        guard total > 0 else { return 0 }
        return Int((Double(seatedGuestsCount) / Double(total)) * 100)
    }

    private var attendingGuestsCount: Int {
        guestStore.guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
    }

    private var seatedGuestsCount: Int {
        guestStore.guests.filter { $0.tableAssignment != nil }.count
    }

    private var unseatedDietaryCount: Int {
        guestStore.guests.filter { guest in
            guest.tableAssignment == nil &&
            (guest.rsvpStatus == .attending || guest.rsvpStatus == .confirmed) &&
            (guest.dietaryRestrictions ?? "").isEmpty == false
        }.count
    }

    // MARK: - Vendor Status Card

    private var vendorStatusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            cardHeader(
                icon: "storefront.fill",
                title: "Vendor Status",
                iconColor: SemanticColors.textTertiary
            )

            // Booking Progress label and percentage
            HStack {
                Text("Booking Progress")
                    .font(Typography.caption)
                    .textCase(.uppercase)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text("\(vendorProgressPercentage)%")
                    .font(Typography.bodySmall)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Progress bar
            vendorProgressBar

            // Critical missing vendors section
            if !criticalMissingVendors.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BlushPink.base)

                        Text("Critical Missing")
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundColor(BlushPink.base)
                    }

                    // Vendor tags
                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(criticalMissingVendors, id: \.self) { vendor in
                            Text(vendor)
                                .font(Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(BlushPink.hover)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .fill(BlushPink.background)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                                .stroke(BlushPink.border, lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
            }
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var vendorProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(SemanticColors.borderPrimaryLight)
                    .frame(height: 10)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(SemanticColors.primaryAction)
                    .frame(width: geometry.size.width * CGFloat(vendorProgressPercentage) / 100, height: 10)
            }
        }
        .frame(height: 10)
    }

    private var vendorProgressPercentage: Int {
        let total = vendorStore.vendors.count
        guard total > 0 else { return 0 }
        let booked = vendorStore.vendors.filter { $0.isBooked == true }.count
        return Int((Double(booked) / Double(total)) * 100)
    }

    /// Critical vendor categories that are not yet booked
    private var criticalMissingVendors: [String] {
        // Define critical vendor categories
        let criticalCategories = ["Officiant", "Photographer", "Catering", "Day-of Coordinator", "DJ", "Florist"]

        // Get booked vendor categories
        let bookedCategories = Set(vendorStore.vendors
            .filter { $0.isBooked == true }
            .compactMap { $0.vendorType })

        // Return critical categories not yet booked
        return criticalCategories.filter { category in
            !bookedCategories.contains(where: { $0.localizedCaseInsensitiveContains(category) })
        }.prefix(3).map { $0 } // Limit to 3 for display
    }

    // MARK: - Special Attention Compact Card (3rd Column)

    /// Compact version of special attention for the 3-column grid
    private var specialAttentionCompactCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(
                icon: "exclamationmark.triangle.fill",
                title: "Needs Attention",
                iconColor: SemanticColors.statusWarning
            )

            // Compact stats grid
            VStack(spacing: Spacing.sm) {
                compactAttentionRow(
                    icon: "leaf.fill",
                    title: "Dietary Needs",
                    count: dietaryRequirementsCount,
                    color: SemanticColors.statusSuccess
                )

                compactAttentionRow(
                    icon: "figure.roll",
                    title: "Accessibility",
                    count: accessibilityNeedsCount,
                    color: SemanticColors.statusInfo
                )

                compactAttentionRow(
                    icon: "star.fill",
                    title: "Wedding Party",
                    count: weddingPartyCount,
                    color: SoftLavender.base
                )
            }

            // View all link
            Divider()
                .background(SemanticColors.borderPrimaryLight)

            Button(action: { coordinator.navigate(to: .guests) }) {
                HStack(spacing: Spacing.xs) {
                    Text("View all special guests")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.primaryAction)

                    Image(systemName: "arrow.forward")
                        .font(.system(size: 10))
                        .foregroundColor(SemanticColors.primaryAction)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.lg)
    }

    private func compactAttentionRow(icon: String, title: String, count: Int, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            // Title
            Text(title)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            Spacer()

            // Count badge
            Text("\(count)")
                .font(Typography.bodySmall)
                .fontWeight(.bold)
                .foregroundColor(count > 0 ? color : SemanticColors.textTertiary)
                .frame(minWidth: 24)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(count > 0 ? color.opacity(0.1) : SemanticColors.backgroundSecondary)
                )
        }
    }

    // MARK: - Special Attention Section

    private var specialAttentionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.statusWarning)

                Text("Special Attention")
                    .font(Typography.title3)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Attention cards
            HStack(spacing: Spacing.lg) {
                specialAttentionCard(
                    icon: "leaf.fill",
                    title: "Dietary Requirements",
                    count: dietaryRequirementsCount,
                    color: .green
                )

                specialAttentionCard(
                    icon: "figure.roll",
                    title: "Accessibility Needs",
                    count: accessibilityNeedsCount,
                    color: .blue
                )

                specialAttentionCard(
                    icon: "star.fill",
                    title: "Wedding Party",
                    count: weddingPartyCount,
                    color: .purple
                )
            }
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var dietaryRequirementsCount: Int {
        guestStore.guests.filter { guest in
            (guest.dietaryRestrictions ?? "").isEmpty == false || guest.mealOption != nil
        }.count
    }

    private var accessibilityNeedsCount: Int {
        guestStore.guests.filter { guest in
            guest.accessibilityNeeds != nil && !guest.accessibilityNeeds!.isEmpty
        }.count
    }

    private var weddingPartyCount: Int {
        guestStore.guests.filter { $0.isWeddingParty }.count
    }

    private func specialAttentionCard(icon: String, title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Text(title)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Text("\(count)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(count > 0 ? color : SemanticColors.textSecondary)

            Text(count == 1 ? "guest" : "guests")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Financial Planning Section

    private var financialPlanningSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(SemanticColors.primaryAction)

                Text("Financial Planning")
                    .font(Typography.title3)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Top row: Monthly Affordability + Gifts
            HStack(alignment: .top, spacing: Spacing.lg) {
                monthlyAffordabilityCard
                    .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)

                giftsContributionsCard
                    .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
            }

            // Bottom: Upcoming Payments Table
            upcomingPaymentsTable
        }
    }

    // MARK: - Monthly Affordability Card

    private var monthlyAffordabilityCard: some View {
        let totalBudget = budgetStore.actualTotalBudget
        let totalSpent = budgetStore.totalSpent
        let monthsUntilWedding = max(1, daysUntilWedding / 30)
        let remaining = max(0, totalBudget - totalSpent)
        let monthlyAvailable = remaining / Double(monthsUntilWedding)

        // Partner contributions (simulated - could be from settings)
        let partner1Name = settingsStore.settings.global.partner1FullName.isEmpty ? "Partner 1" : settingsStore.settings.global.partner1FullName
        let partner2Name = settingsStore.settings.global.partner2FullName.isEmpty ? "Partner 2" : settingsStore.settings.global.partner2FullName
        let partner1Contribution = totalSpent * 0.55 // Example split
        let partner2Contribution = totalSpent * 0.45

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                NativeIconBadge(systemName: "dollarsign.circle", color: SemanticColors.primaryAction, size: 36)

                Text("Monthly Affordability")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Partner contribution bars
            HStack(spacing: Spacing.md) {
                partnerContributionBar(name: partner1Name, amount: partner1Contribution, color: SemanticColors.primaryAction)
                partnerContributionBar(name: partner2Name, amount: partner2Contribution, color: SemanticColors.statusSuccess)
            }

            // Months saved progress
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Months Saved: \(monthsSaved)")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textSecondary)

                    Spacer()

                    Text("Target: \(monthsUntilWedding)")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textTertiary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SemanticColors.borderPrimaryLight)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [SemanticColors.primaryAction, SoftLavender.base],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(min(1, Double(monthsSaved) / Double(max(1, monthsUntilWedding)))), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Footer stats
            Divider()
                .background(SemanticColors.borderPrimaryLight)

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("REQUIRED MONTHLY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SemanticColors.textTertiary)
                        .tracking(0.5)

                    Text(formatCurrency(monthlyAvailable))
                        .font(Typography.bodySmall)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text("BUFFER")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SemanticColors.textTertiary)
                            .tracking(0.5)

                        Circle()
                            .fill(SemanticColors.statusSuccess)
                            .frame(width: 8, height: 8)
                    }

                    Text(bufferStatus)
                        .font(Typography.bodySmall)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.statusSuccess)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func partnerContributionBar(name: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(name)
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text(formatCurrency(amount))
                    .font(Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Mini bar chart visualization
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color.opacity(0.3 + Double(index) * 0.14))
                        .frame(width: 4, height: CGFloat(4 + index * 3))
                }
            }
            .frame(height: 24)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimaryLight, lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }

    private var monthsSaved: Int {
        // Calculate based on budget progress
        let totalBudget = budgetStore.actualTotalBudget
        let totalSpent = budgetStore.totalSpent
        guard totalBudget > 0 else { return 0 }
        let progress = totalSpent / totalBudget
        return Int(progress * Double(max(1, daysUntilWedding / 30)))
    }

    private var bufferStatus: String {
        let totalBudget = budgetStore.actualTotalBudget
        let totalSpent = budgetStore.totalSpent
        let remaining = totalBudget - totalSpent
        let monthsUntilWedding = max(1, daysUntilWedding / 30)
        let monthlyRequired = totalBudget / Double(monthsUntilWedding)
        let actualMonthlySpent = totalSpent / Double(max(1, monthsSaved))
        let buffer = monthlyRequired - actualMonthlySpent

        if buffer > 0 {
            return "+\(formatCurrency(buffer)) safe"
        } else {
            return "\(formatCurrency(abs(buffer))) over"
        }
    }

    // MARK: - Gifts & Contributions Card

    private var giftsContributionsCard: some View {
        let totalGifts = budgetStore.gifts.totalReceived
        let totalPending = budgetStore.gifts.totalPending
        let totalExpected = totalGifts + totalPending

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                NativeIconBadge(systemName: "gift.fill", color: BlushPink.base, size: 36)

                Text("Gifts & Contributions")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Content: Donut + Contributor list
            HStack(spacing: Spacing.xl) {
                // Donut chart
                giftsDonutChart(received: totalGifts, pending: totalPending, total: totalExpected)

                // Contributor list
                giftsContributorList
            }

            // Footer summary
            HStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.xs) {
                    Text("Received:")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(formatCurrency(totalGifts))
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Rectangle()
                    .fill(SemanticColors.borderPrimaryLight)
                    .frame(width: 1, height: 16)

                HStack(spacing: Spacing.xs) {
                    Text("Pending:")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(formatCurrency(totalPending))
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.statusWarning)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(SemanticColors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.borderPrimaryLight, lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func giftsDonutChart(received: Double, pending: Double, total: Double) -> some View {
        ZStack {
            if #available(macOS 13.0, *) {
                Chart {
                    SectorMark(
                        angle: .value("Received", received),
                        innerRadius: .ratio(0.7),
                        angularInset: 1
                    )
                    .foregroundStyle(BlushPink.base)

                    SectorMark(
                        angle: .value("Pending", pending),
                        innerRadius: .ratio(0.7),
                        angularInset: 1
                    )
                    .foregroundStyle(SemanticColors.borderPrimaryLight)
                }
                .chartLegend(.hidden)
                .frame(width: 112, height: 112)
            }

            // Center label
            VStack(spacing: Spacing.xxs) {
                Text("Total")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textTertiary)

                Text(formatCurrencyShort(total))
                    .font(Typography.bodySmall)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
            }
        }
    }

    private var giftsContributorList: some View {
        // Sample contributor data - would come from gifts store
        let contributors: [(name: String, description: String, status: String)] = [
            ("Parents (Her)", "Venue Deposit", "Received"),
            ("Parents (Him)", "Rehearsal Dinner", "Pledged"),
            ("Grandparents", "Dress Fund", "Received")
        ]

        return VStack(spacing: Spacing.sm) {
            ForEach(contributors, id: \.name) { contributor in
                contributorRow(name: contributor.name, description: contributor.description, status: contributor.status)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func contributorRow(name: String, description: String, status: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name)
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)
            }

            Spacer()

            // Status badge
            HStack(spacing: Spacing.xxs) {
                Text(status)
                    .font(.system(size: 10, weight: .bold))

                if status == "Received" {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                }
            }
            .foregroundColor(status == "Received" ? SemanticColors.statusSuccess : SemanticColors.statusWarning)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(status == "Received" ? SemanticColors.statusSuccess.opacity(0.1) : SemanticColors.statusWarning.opacity(0.1))
            )
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
    }

    /// Format currency in short form (e.g., $8.5k)
    private func formatCurrencyShort(_ value: Double) -> String {
        if value >= 1000 {
            let kValue = value / 1000
            if kValue == floor(kValue) {
                return "$\(Int(kValue))k"
            }
            return String(format: "$%.1fk", kValue)
        }
        return formatCurrency(value)
    }

    // MARK: - Upcoming Payments Table

    private var upcomingPaymentsTable: some View {
        let upcomingPayments = budgetStore.payments.paymentSchedules
            .filter { !$0.paid }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(5)
        let totalDue = upcomingPayments.reduce(0.0) { $0 + $1.amount }

        return VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Text("Upcoming Payments")
                            .font(Typography.heading)
                            .foregroundColor(SemanticColors.textPrimary)

                        if !upcomingPayments.isEmpty {
                            Text("\(upcomingPayments.count) Due")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(BlushPink.base)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(BlushPink.background)
                                )
                        }
                    }

                    Text("Overview for Next 60 Days")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                // Filter buttons
                HStack(spacing: Spacing.sm) {
                    filterButton("All", isSelected: true)
                    filterButton("Vendor Fees", isSelected: false)
                    filterButton("Purchases", isSelected: false)
                }
            }
            .padding(Spacing.xl)
            .background(SemanticColors.backgroundPrimary)

            Divider()
                .background(SemanticColors.borderPrimaryLight)

            // Table header
            HStack(spacing: 0) {
                tableHeaderCell("PAYMENT NAME", width: .infinity, alignment: .leading)
                tableHeaderCell("CATEGORY", width: 120, alignment: .leading)
                tableHeaderCell("DUE DATE", width: 100, alignment: .leading)
                tableHeaderCell("AMOUNT", width: 100, alignment: .trailing)
                tableHeaderCell("STATUS", width: 100, alignment: .center)
                tableHeaderCell("", width: 50, alignment: .center)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(SemanticColors.backgroundSecondary)

            Divider()
                .background(SemanticColors.borderPrimaryLight)

            // Table rows
            if upcomingPayments.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(SemanticColors.statusSuccess)

                    Text("No upcoming payments")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxl)
            } else {
                VStack(spacing: 0) {
                    ForEach(upcomingPayments) { payment in
                        paymentTableRow(payment)

                        Divider()
                            .background(SemanticColors.borderPrimaryLight.opacity(0.5))
                    }
                }
            }

            // Footer
            HStack {
                Spacer()

                HStack(spacing: Spacing.xl) {
                    Text("Total Due (60d): ")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    +
                    Text(formatCurrency(totalDue))
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("Items: ")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    +
                    Text("\(upcomingPayments.count)")
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(SemanticColors.backgroundSecondary)
        }
        .background(SemanticColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderPrimaryLight, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func filterButton(_ title: String, isSelected: Bool) -> some View {
        Button(action: {}) {
            Text(title)
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? SemanticColors.primaryAction : SemanticColors.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? SemanticColors.primaryAction.opacity(0.1) : SemanticColors.backgroundSecondary)
                )
        }
        .buttonStyle(.plain)
    }

    private func tableHeaderCell(_ title: String, width: CGFloat?, alignment: Alignment) -> some View {
        Group {
            if let width = width, width != .infinity {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SemanticColors.textTertiary)
                    .tracking(0.5)
                    .frame(width: width, alignment: alignment)
            } else {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SemanticColors.textTertiary)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
    }

    private func paymentTableRow(_ payment: PaymentSchedule) -> some View {
        let dueStatus = paymentDueStatus(payment.dueDate)

        return HStack(spacing: 0) {
            // Payment name
            Text(payment.vendor)
                .font(Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Category
            Text(payment.vendorType ?? "General")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 120, alignment: .leading)

            // Due date
            HStack(spacing: Spacing.xs) {
                Text(dueStatus.text)
                    .font(Typography.bodySmall)
                    .fontWeight(dueStatus.isUrgent ? .bold : .regular)
                    .foregroundColor(dueStatus.color)

                if dueStatus.showIndicator {
                    Circle()
                        .fill(dueStatus.color)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 100, alignment: .leading)

            // Amount
            Text(formatCurrency(payment.amount))
                .font(Typography.bodySmall)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)
                .frame(width: 100, alignment: .trailing)

            // Status
            paymentStatusBadge(payment)
                .frame(width: 100)

            // Action
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .buttonStyle(.plain)
            .frame(width: 50)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(SemanticColors.backgroundPrimary)
        .contentShape(Rectangle())
    }

    private func paymentDueStatus(_ dueDate: Date) -> (text: String, color: Color, isUrgent: Bool, showIndicator: Bool) {
        let days = DateFormatting.daysBetween(from: Date(), to: dueDate, in: userTimezone)

        if days < 0 {
            return ("Overdue", BlushPink.base, true, true)
        } else if days == 0 {
            return ("Today", BlushPink.base, true, true)
        } else if days == 1 {
            return ("Tomorrow", SemanticColors.statusWarning, true, false)
        } else if days <= 7 {
            return ("\(days) days", SemanticColors.statusWarning, false, false)
        } else {
            return (DateFormatting.formatDateShort(dueDate, timezone: userTimezone), SemanticColors.textSecondary, false, false)
        }
    }

    private func paymentStatusBadge(_ payment: PaymentSchedule) -> some View {
        let (text, bgColor, textColor) = paymentStatusStyle(payment)

        return Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(textColor.opacity(0.2), lineWidth: 1)
                    )
            )
    }

    private func paymentStatusStyle(_ payment: PaymentSchedule) -> (String, Color, Color) {
        if payment.paid {
            return ("Paid", SemanticColors.statusSuccess.opacity(0.1), SemanticColors.statusSuccess)
        }

        let days = DateFormatting.daysBetween(from: Date(), to: payment.dueDate, in: userTimezone)
        if days < 0 {
            return ("Overdue", BlushPink.background, BlushPink.base)
        } else if days <= 1 {
            return ("Unpaid", BlushPink.background, BlushPink.base)
        } else if days <= 7 {
            return ("Scheduled", SemanticColors.statusWarning.opacity(0.1), SemanticColors.statusWarning)
        } else {
            return ("Pending", SemanticColors.backgroundSecondary, SemanticColors.textSecondary)
        }
    }

    // MARK: - Category Priorities Section

    private var categoryPrioritiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 18))
                        .foregroundColor(SemanticColors.textTertiary)

                    Text("Category Priorities")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Spacer()

                // Toggle for "Show Essential Only"
                HStack(spacing: Spacing.sm) {
                    Text("Show Essential Only")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Toggle("", isOn: .constant(false))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }

            // Priority distribution bar
            priorityDistributionBar

            // Priority cards grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                priorityCard(
                    level: "Critical",
                    levelColor: BlushPink.base,
                    bgColor: BlushPink.background.opacity(0.3),
                    borderColor: BlushPink.border,
                    categoryName: "Venue & Catering",
                    budget: 15000,
                    progress: 0.9,
                    showDiamond: true
                )

                priorityCard(
                    level: "High",
                    levelColor: SemanticColors.statusWarning,
                    bgColor: SemanticColors.statusWarning.opacity(0.1),
                    borderColor: SemanticColors.statusWarning.opacity(0.3),
                    categoryName: "Photography",
                    budget: 3500,
                    progress: 0.4,
                    showDiamond: false
                )

                priorityCard(
                    level: "Medium",
                    levelColor: SemanticColors.textSecondary,
                    bgColor: SemanticColors.backgroundSecondary,
                    borderColor: SemanticColors.borderPrimaryLight,
                    categoryName: "Transportation",
                    budget: 1200,
                    progress: 0.15,
                    showDiamond: false
                )

                priorityCard(
                    level: "Low",
                    levelColor: SemanticColors.textTertiary,
                    bgColor: SemanticColors.backgroundPrimary,
                    borderColor: SemanticColors.borderPrimaryLight,
                    categoryName: "Favors & Gifts",
                    budget: 500,
                    progress: 0.0,
                    showLock: true
                )
            }
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var priorityDistributionBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Critical (20%)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [BlushPink.base, BlushPink.hover],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 0.20)

                // High (35%)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [SemanticColors.statusWarning, SemanticColors.statusWarning.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 0.35)

                // Medium (25%)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [SemanticColors.textTertiary.opacity(0.5), SemanticColors.textTertiary.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 0.25)

                // Low (20%)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [SemanticColors.borderPrimaryLight, SemanticColors.backgroundSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 0.20)
            }
        }
        .frame(height: 16)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.bottom, Spacing.lg)
    }

    private func priorityCard(
        level: String,
        levelColor: Color,
        bgColor: Color,
        borderColor: Color,
        categoryName: String,
        budget: Double,
        progress: Double,
        showDiamond: Bool = false,
        showLock: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Level indicator
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(levelColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: levelColor.opacity(0.6), radius: 4, x: 0, y: 0)

                Text(level.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(levelColor)
                    .tracking(0.5)

                Spacer()

                if showDiamond {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 12))
                        .foregroundColor(levelColor)
                }

                if showLock {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }

            // Category name
            Text(categoryName)
                .font(Typography.bodySmall)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(levelColor)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            // Footer
            HStack {
                Text("Budget: \(formatCurrencyShort(budget))")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                // Progress dots
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: Double(index) / 3.0 < progress ? "circle.fill" : "circle")
                            .font(.system(size: 6))
                            .foregroundColor(levelColor.opacity(Double(index) / 3.0 < progress ? 1 : 0.3))
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
    }

    // MARK: - Needs Your Approval Section

    private var needsApprovalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Needs Your Approval")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                // Pending badge
                HStack(spacing: Spacing.xs) {
                    Text("2 Pending")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SemanticColors.statusWarning)

                    Circle()
                        .fill(SemanticColors.statusWarning)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(SemanticColors.statusWarning.opacity(0.1))
                )
            }

            // Approval items
            VStack(spacing: Spacing.md) {
                approvalItem(
                    title: "Extra Florals for Arch",
                    requestedBy: "Wedding Planner",
                    amount: 450.00
                )

                approvalItem(
                    title: "Upgrade to Premium Bar",
                    requestedBy: settingsStore.settings.global.partner2FullName.isEmpty ? "Partner" : settingsStore.settings.global.partner2FullName,
                    amount: 1200.00
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private func approvalItem(title: String, requestedBy: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.bodySmall)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("Requested by \(requestedBy)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                Text(formatCurrency(amount))
                    .font(Typography.bodySmall)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Action buttons
            HStack(spacing: Spacing.sm) {
                Button(action: {}) {
                    Text("Approve")
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(SemanticColors.statusSuccess)
                        )
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Text("Decline")
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(SemanticColors.backgroundPrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                                        .stroke(SemanticColors.borderPrimaryLight, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.backgroundSecondary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimaryLight, lineWidth: 1)
                )
        )
    }

    // MARK: - Recent Transactions Section

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.textTertiary)

                    Text("Recent Transactions")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textTertiary)
                }
                .buttonStyle(.plain)
            }

            // Transaction timeline
            VStack(alignment: .leading, spacing: 0) {
                transactionTimelineItem(
                    date: "Today, 10:23 AM",
                    description: "Paid Cake Tasting Fee to Sweet Delights.",
                    highlight: "Cake Tasting Fee",
                    amount: "-$50.00",
                    amountColor: BlushPink.base,
                    isLast: false
                )

                transactionTimelineItem(
                    date: "Yesterday, 4:15 PM",
                    description: "Deposit cleared for Videographer.",
                    highlight: "Videographer",
                    amount: "Verified",
                    amountColor: SemanticColors.statusSuccess,
                    isLast: false
                )

                transactionTimelineItem(
                    date: "Feb 20, 9:00 AM",
                    description: "Added new budget category: Guest Favors.",
                    highlight: "Guest Favors",
                    amount: nil,
                    amountColor: nil,
                    isLast: true
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private func transactionTimelineItem(
        date: String,
        description: String,
        highlight: String,
        amount: String?,
        amountColor: Color?,
        isLast: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(SemanticColors.borderPrimaryLight)
                    .frame(width: 8, height: 8)

                if !isLast {
                    Rectangle()
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(width: 1)
                        .padding(.vertical, Spacing.xs)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(date)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)

                // Description with highlight
                Text(attributedDescription(description, highlight: highlight))
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)

                if let amount = amount, let color = amountColor {
                    Text(amount)
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
            .padding(.bottom, isLast ? 0 : Spacing.md)
        }
    }

    private func attributedDescription(_ text: String, highlight: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: highlight) {
            attributed[range].foregroundColor = SemanticColors.textPrimary
            attributed[range].font = Typography.bodySmall.bold()
        }
        return attributed
    }

    // MARK: - Helper Views

    private func cardHeader(icon: String, title: String, iconColor: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            NativeIconBadge(systemName: icon, color: iconColor, size: 36)

            Text(title)
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
        }
    }

    /// Formats a value as currency using short format
    private func formatCurrency(_ value: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: value)) ?? "$0"
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        isLoading = true

        // Load all stores in parallel
        async let loadGuests: () = guestStore.loadGuestData()
        async let loadTasks: () = taskStore.loadTasks()
        async let loadVendors: () = vendorStore.loadVendors()
        async let loadBudget: () = budgetStore.loadBudgetData()
        async let loadTimeline: () = timelineStore.loadWeddingDayEvents()

        await loadGuests
        await loadTasks
        await loadVendors
        await loadBudget
        await loadTimeline

        // Calculate days until wedding - parse from settings string
        let weddingDateString = settingsStore.settings.global.weddingDate
        if let weddingDate = DateFormatting.parseDateFromDatabase(weddingDateString) {
            daysUntilWedding = DateFormatting.daysBetween(from: Date(), to: weddingDate, in: userTimezone)
        }

        // Calculate overall readiness
        calculateOverallReadiness()

        isLoading = false
    }

    private func calculateOverallReadiness() {
        var totalWeight: Double = 0
        var weightedProgress: Double = 0

        // Tasks progress (weight: 30%)
        let taskWeight: Double = 0.30
        let completedTasks = taskStore.tasks.filter { $0.status == .completed }.count
        let totalTasks = max(1, taskStore.tasks.count)
        weightedProgress += taskWeight * Double(completedTasks) / Double(totalTasks)
        totalWeight += taskWeight

        // RSVP progress (weight: 25%)
        let rsvpWeight: Double = 0.25
        let respondedGuests = guestStore.guests.filter { $0.rsvpStatus != .pending && $0.rsvpStatus != .invited }.count
        let totalGuests = max(1, guestStore.guests.count)
        weightedProgress += rsvpWeight * Double(respondedGuests) / Double(totalGuests)
        totalWeight += rsvpWeight

        // Vendor progress (weight: 25%)
        let vendorWeight: Double = 0.25
        let bookedVendors = vendorStore.vendors.filter { $0.isBooked == true }.count
        let totalVendors = max(1, vendorStore.vendors.count)
        weightedProgress += vendorWeight * Double(bookedVendors) / Double(totalVendors)
        totalWeight += vendorWeight

        // Budget progress (weight: 20%)
        let budgetWeight: Double = 0.20
        let totalBudget = budgetStore.actualTotalBudget
        let budgetProgress = totalBudget > 0 ? min(1, budgetStore.totalSpent / totalBudget) : 0
        weightedProgress += budgetWeight * budgetProgress
        totalWeight += budgetWeight

        overallReadiness = totalWeight > 0 ? weightedProgress / totalWeight : 0
    }
}

// MARK: - Preview

#Preview {
    GeneralDashboardViewV1()
        .environmentObject(AppCoordinator.shared)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1400, height: 1000)
}
