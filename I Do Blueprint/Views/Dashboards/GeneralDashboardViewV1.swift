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
            // Countdown Card
            countdownCard

            // Overall Readiness Card
            readinessCard
        }
    }

    private var countdownCard: some View {
        HStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(daysUntilWedding)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Days Until Your Wedding")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    private var readinessCard: some View {
        HStack(spacing: Spacing.lg) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(SemanticColors.borderPrimaryLight, lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: overallReadiness)
                    .stroke(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(overallReadiness * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Overall Readiness")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("You're on track!")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Main Content Grid

    private var mainContentGrid: some View {
        HStack(alignment: .top, spacing: Spacing.xxl) {
            // Left column
            VStack(spacing: Spacing.xxl) {
                guestRSVPsCard
                planningTasksCard
            }
            .frame(maxWidth: .infinity)

            // Right column
            VStack(spacing: Spacing.xxl) {
                eventTimelineCard
                HStack(spacing: Spacing.xxl) {
                    seatingProgressCard
                    vendorStatusCard
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Guest RSVPs Card

    private var guestRSVPsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            cardHeader(
                icon: "person.2.fill",
                title: "Guest RSVPs",
                iconColor: .blue
            )

            // Donut Chart
            guestRSVPDonutChart

            // Legend
            guestRSVPLegend
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var guestRSVPDonutChart: some View {
        let guests = guestStore.guests
        let attending = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let awaiting = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited || $0.rsvpStatus == .maybe }.count
        let declined = guests.filter { $0.rsvpStatus == .declined }.count
        let total = guests.count

        return HStack(spacing: Spacing.xxl) {
            // Donut chart
            ZStack {
                if #available(macOS 13.0, *) {
                    Chart {
                        SectorMark(
                            angle: .value("Attending", attending),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(AppColors.Guest.confirmed)

                        SectorMark(
                            angle: .value("Awaiting", awaiting),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(AppColors.Guest.pending)

                        SectorMark(
                            angle: .value("Declined", declined),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(AppColors.Guest.declined)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 160, height: 160)
                }

                // Center label
                VStack(spacing: Spacing.xxs) {
                    Text("\(total)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Invited")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            // Stats
            VStack(alignment: .leading, spacing: Spacing.md) {
                rsvpStatRow(label: "Attending", value: attending, color: AppColors.Guest.confirmed, icon: "checkmark.circle.fill")
                rsvpStatRow(label: "Awaiting", value: awaiting, color: AppColors.Guest.pending, icon: "clock.fill")
                rsvpStatRow(label: "Declined", value: declined, color: AppColors.Guest.declined, icon: "xmark.circle.fill")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private func rsvpStatRow(label: String, value: Int, color: Color, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(label)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)

            Spacer()

            Text("\(value)")
                .font(Typography.numberMedium)
                .foregroundColor(SemanticColors.textPrimary)
        }
    }

    private var guestRSVPLegend: some View {
        HStack(spacing: Spacing.lg) {
            legendItem(color: AppColors.Guest.confirmed, label: "Attending")
            legendItem(color: AppColors.Guest.pending, label: "Awaiting")
            legendItem(color: AppColors.Guest.declined, label: "Declined")
        }
        .frame(maxWidth: .infinity)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    // MARK: - Planning Tasks Card

    private var planningTasksCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                cardHeader(
                    icon: "checklist",
                    title: "Planning Tasks",
                    iconColor: .purple
                )

                Spacer()

                // Progress indicator
                let completedCount = taskStore.tasks.filter { $0.status == .completed }.count
                let totalCount = taskStore.tasks.count
                Text("\(completedCount)/\(totalCount) completed")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            // Task list
            taskList
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var taskList: some View {
        let upcomingTasks = Array(taskStore.tasks
            .filter { $0.status != .completed && $0.status != .cancelled }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(5))

        return VStack(spacing: Spacing.md) {
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
        HStack(spacing: Spacing.md) {
            // Status indicator
            Circle()
                .fill(taskPriorityColor(task.priority))
                .frame(width: 8, height: 8)

            // Task info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(task.taskName)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                if let dueDate = task.dueDate {
                    Text(DateFormatting.formatRelativeDate(dueDate, timezone: userTimezone))
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()

            // Priority badge
            taskPriorityBadge(task.priority)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.backgroundSecondary.opacity(0.5))
        )
    }

    private func taskPriorityColor(_ priority: WeddingTaskPriority) -> Color {
        switch priority {
        case .urgent: return SemanticColors.statusError
        case .high: return SemanticColors.statusWarning
        case .medium: return SemanticColors.statusInfo
        case .low: return SemanticColors.statusSuccess
        }
    }

    private func taskPriorityBadge(_ priority: WeddingTaskPriority) -> some View {
        Text(priority.rawValue.capitalized)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(taskPriorityColor(priority).opacity(0.15))
            .foregroundColor(taskPriorityColor(priority))
            .clipShape(Capsule())
    }

    // MARK: - Event Timeline Card

    private var eventTimelineCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            cardHeader(
                icon: "calendar",
                title: "Event Timeline",
                iconColor: .orange
            )

            // Timeline
            eventTimeline
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var eventTimeline: some View {
        let events = Array(timelineStore.weddingDayEvents
            .sorted { ($0.startTime ?? $0.eventDate) < ($1.startTime ?? $1.eventDate) }
            .prefix(5))

        return VStack(spacing: 0) {
            if events.isEmpty {
                emptyTimelineView
            } else {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    timelineEventRow(event, isLast: index == events.count - 1)
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

    private func timelineEventRow(_ event: WeddingDayEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(eventCategoryColor(event.category))
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            // Event info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(event.eventName)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                if let startTime = event.startTime {
                    Text(DateFormatting.formatTime(startTime, timezone: userTimezone))
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.bottom, isLast ? 0 : Spacing.lg)

            Spacer()
        }
    }

    private func eventCategoryColor(_ category: WeddingDayEventCategory) -> Color {
        switch category {
        case .ceremony: return SemanticColors.statusSuccess
        case .reception: return SemanticColors.statusInfo
        case .photos: return SemanticColors.statusWarning
        case .bridalPrep, .groomPrep: return .purple
        case .cocktail, .dinner: return .orange
        case .dancing, .other: return SemanticColors.textSecondary
        }
    }

    // MARK: - Seating Progress Card

    private var seatingProgressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            cardHeader(
                icon: "rectangle.split.3x3",
                title: "Seating Progress",
                iconColor: .teal
            )

            // Progress
            seatingProgressContent
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    private var seatingProgressContent: some View {
        let totalGuests = guestStore.guests.count
        let seatedGuests = guestStore.guests.filter { $0.tableAssignment != nil }.count
        let progress = totalGuests > 0 ? Double(seatedGuests) / Double(totalGuests) : 0

        return VStack(spacing: Spacing.md) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(SemanticColors.borderPrimaryLight, lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.teal, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: Spacing.xxs) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Seated")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            // Stats
            HStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.xxs) {
                    Text("\(seatedGuests)")
                        .font(Typography.numberMedium)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Assigned")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                VStack(spacing: Spacing.xxs) {
                    Text("\(totalGuests - seatedGuests)")
                        .font(Typography.numberMedium)
                        .foregroundColor(totalGuests - seatedGuests > 0 ? SemanticColors.statusWarning : SemanticColors.textPrimary)
                    Text("Remaining")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Vendor Status Card

    private var vendorStatusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            cardHeader(
                icon: "building.2",
                title: "Vendor Status",
                iconColor: .indigo
            )

            // Status content
            vendorStatusContent
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    private var vendorStatusContent: some View {
        let totalVendors = vendorStore.vendors.count
        let bookedVendors = vendorStore.vendors.filter { $0.isBooked == true }.count
        let progress = totalVendors > 0 ? Double(bookedVendors) / Double(totalVendors) : 0

        return VStack(spacing: Spacing.md) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(SemanticColors.borderPrimaryLight, lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: Spacing.xxs) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Booked")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            // Stats
            HStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.xxs) {
                    Text("\(bookedVendors)")
                        .font(Typography.numberMedium)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Confirmed")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                VStack(spacing: Spacing.xxs) {
                    Text("\(totalVendors - bookedVendors)")
                        .font(Typography.numberMedium)
                        .foregroundColor(totalVendors - bookedVendors > 0 ? SemanticColors.statusWarning : SemanticColors.textPrimary)
                    Text("Pending")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
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

            // Financial cards
            HStack(alignment: .top, spacing: Spacing.xxl) {
                monthlyAffordabilityCard
                giftsContributionsCard
                upcomingPaymentsCard
            }
        }
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xl)
    }

    private var monthlyAffordabilityCard: some View {
        let totalBudget = budgetStore.actualTotalBudget
        let totalSpent = budgetStore.totalSpent
        let remaining = max(0, totalBudget - totalSpent)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                NativeIconBadge(systemName: "dollarsign.circle", color: .green, size: 36)

                Text("Monthly Affordability")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Text(formatCurrency(remaining / Double(max(1, daysUntilWedding / 30))))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(SemanticColors.textPrimary)

            Text("per month available")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(1, totalSpent / max(1, totalBudget)), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Spent: \(formatCurrency(totalSpent))")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text("Budget: \(formatCurrency(totalBudget))")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var giftsContributionsCard: some View {
        let totalGifts = budgetStore.gifts.totalReceived
        let totalOwed = budgetStore.gifts.totalPending

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                NativeIconBadge(systemName: "gift", color: .pink, size: 36)

                Text("Gifts & Contributions")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Text(formatCurrency(totalGifts))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(SemanticColors.textPrimary)

            Text("received so far")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            NativeDividerStyle()
                .padding(.vertical, Spacing.xs)

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Pending")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(formatCurrency(totalOwed))
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(totalOwed > 0 ? SemanticColors.statusWarning : SemanticColors.textPrimary)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var upcomingPaymentsCard: some View {
        let upcomingPayments = budgetStore.payments.paymentSchedules
            .filter { !$0.paid && $0.dueDate > Date() }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(3)

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                NativeIconBadge(systemName: "calendar.badge.clock", color: .orange, size: 36)

                Text("Upcoming Payments")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            if upcomingPayments.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(SemanticColors.statusSuccess)

                    Text("No upcoming payments")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(upcomingPayments) { payment in
                        paymentRow(payment)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func paymentRow(_ payment: PaymentSchedule) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(payment.vendor)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                Text(DateFormatting.formatDateMedium(payment.dueDate, timezone: userTimezone))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            Text(formatCurrency(payment.amount))
                .font(Typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(SemanticColors.backgroundSecondary.opacity(0.5))
        )
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
