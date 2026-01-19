//
//  MoneyManagementViewV2.swift
//  I Do Blueprint
//
//  Unified money management view combining contributions, gifts, and pledges
//  Replaces: MoneyTrackerView, MoneyReceivedView, MoneyOwedView
//

import Charts
import SwiftUI

// MARK: - MoneyManagementViewV2

struct MoneyManagementViewV2: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @Binding var currentPage: BudgetPage

    @State private var selectedTimeRange: TimeRange = .sixMonths
    @State private var showingAddContribution = false
    @State private var searchText = ""
    @State private var selectedTab: MoneyTab = .all

    private var giftsStore: GiftsStore { budgetStore.gifts }

    var body: some View {
        ZStack {
            MeshGradientBackground()

            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    // Summary Cards
                    MoneyManagementSummaryCards(
                        totalContributions: totalContributions,
                        giftsReceived: totalGiftsReceived,
                        pledgedAmount: totalPledged,
                        goalProgress: goalProgress,
                        contributorCount: contributorCount,
                        giftItemCount: giftItemCount
                    )

                    // Charts Section
                    MoneyManagementChartsSection(
                        contributions: sortedContributions,
                        selectedTimeRange: $selectedTimeRange
                    )

                    // Goal Tracker Banner
                    MoneyManagementGoalTracker(
                        currentAmount: totalContributions,
                        goalAmount: goalAmount,
                        contributorCount: contributorCount,
                        daysToWedding: daysToWedding,
                        averageContribution: averageContribution,
                        giftItemCount: giftItemCount
                    )

                    // Recent Contributions + Top Contributors
                    MoneyManagementContributionsSection(
                        contributions: sortedContributions,
                        topContributors: topContributors,
                        totalPledged: totalPledged,
                        pendingCount: pendingPledges.count
                    )

                    // Gift Registry Items
                    MoneyManagementGiftRegistry(
                        gifts: physicalGifts,
                        onAddItem: { showingAddContribution = true }
                    )

                    // Pending Pledges
                    MoneyManagementPendingPledges(
                        pledges: pendingPledges,
                        totalPledged: totalPledged
                    )

                    // Contribution Insights
                    MoneyManagementInsights(
                        contributions: sortedContributions
                    )

                    // Thank You Messages Section
                    MoneyManagementThankYouSection(
                        sentCount: thankYouSentCount,
                        pendingCount: thankYouPendingCount
                    )
                }
                .padding(Spacing.xxl)
            }
        }
        .task {
            await giftsStore.loadGiftsData()
        }
        .sheet(isPresented: $showingAddContribution) {
            AddContributionModal()
        }
    }

    // MARK: - Computed Properties

    private var sortedContributions: [GiftOrOwed] {
        giftsStore.giftsAndOwed.sorted { ($0.createdAt) > ($1.createdAt) }
    }

    private var totalContributions: Double {
        giftsStore.totalReceived + giftsStore.totalConfirmed
    }

    private var totalGiftsReceived: Double {
        giftsStore.giftsReceived.reduce(0) { $0 + $1.amount }
    }

    private var totalPledged: Double {
        giftsStore.pendingGifts.reduce(0) { $0 + $1.amount }
    }

    private var pendingPledges: [GiftOrOwed] {
        giftsStore.giftsAndOwed.filter { $0.status == .pending }
    }

    private var physicalGifts: [GiftReceived] {
        giftsStore.giftsReceived.filter { $0.giftType == .gift }
    }

    private var contributorCount: Int {
        let giftContributors = Set(giftsStore.giftsAndOwed.compactMap { $0.fromPerson })
        let receivedContributors = Set(giftsStore.giftsReceived.map { $0.fromPerson })
        return giftContributors.union(receivedContributors).count
    }

    private var giftItemCount: Int {
        giftsStore.giftsReceived.count
    }

    private var goalAmount: Double {
        // Use primary budget scenario total with tax as the goal
        let scenarioTotal = budgetStore.primaryScenarioTotal
        return scenarioTotal > 0 ? scenarioTotal : 35000
    }

    private var goalProgress: Double {
        guard goalAmount > 0 else { return 0 }
        return min(totalContributions / goalAmount, 1.0)
    }

    private var daysToWedding: Int {
        let weddingDateString = settingsStore.settings.global.weddingDate
        guard !weddingDateString.isEmpty,
              let weddingDate = DateFormatting.parseDateFromDatabase(weddingDateString) else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: weddingDate)
        return max(0, components.day ?? 0)
    }

    private var averageContribution: Double {
        guard contributorCount > 0 else { return 0 }
        return totalContributions / Double(contributorCount)
    }

    private var topContributors: [(name: String, amount: Double, relationship: String?)] {
        var contributorAmounts: [String: (amount: Double, relationship: String?)] = [:]

        for gift in giftsStore.giftsAndOwed where gift.status == .confirmed || gift.status == .received {
            if let person = gift.fromPerson {
                let existing = contributorAmounts[person] ?? (0, gift.description)
                contributorAmounts[person] = (existing.amount + gift.amount, existing.relationship)
            }
        }

        for gift in giftsStore.giftsReceived {
            let existing = contributorAmounts[gift.fromPerson] ?? (0, nil)
            contributorAmounts[gift.fromPerson] = (existing.amount + gift.amount, existing.relationship)
        }

        return contributorAmounts
            .map { (name: $0.key, amount: $0.value.amount, relationship: $0.value.relationship) }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
    }

    private var thankYouSentCount: Int {
        giftsStore.giftsReceived.filter { $0.isThankYouSent }.count
    }

    private var thankYouPendingCount: Int {
        giftsStore.giftsReceived.filter { !$0.isThankYouSent }.count
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"
}

enum MoneyTab: String, CaseIterable {
    case all = "All"
    case contributions = "Contributions"
    case gifts = "Gifts"
    case pledges = "Pledges"
}

// MARK: - Summary Cards

struct MoneyManagementSummaryCards: View {
    let totalContributions: Double
    let giftsReceived: Double
    let pledgedAmount: Double
    let goalProgress: Double
    let contributorCount: Int
    let giftItemCount: Int

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.lg) {
            // Total Contributions
            MoneyStatCard(
                icon: "hand.raised.fill",
                iconGradient: [SageGreen.shade400, SageGreen.shade600],
                title: "Total Contributions",
                value: totalContributions.currencyFormatted,
                subtitle: "From \(contributorCount) contributors",
                badge: "+12%",
                badgeColor: SageGreen.shade600
            )

            // Gifts Received
            MoneyStatCard(
                icon: "gift.fill",
                iconGradient: [BlushPink.shade400, BlushPink.shade600],
                title: "Gifts Received",
                value: giftsReceived.currencyFormatted,
                subtitle: "Registry & physical gifts",
                badge: "\(giftItemCount) items",
                badgeColor: SoftLavender.shade600
            )

            // Pledged Amount
            MoneyStatCard(
                icon: "clock.arrow.circlepath",
                iconGradient: [Terracotta.shade400, Terracotta.shade600],
                title: "Pledged Amount",
                value: pledgedAmount.currencyFormatted,
                subtitle: "Pending contributions",
                badge: "Pending",
                badgeColor: Terracotta.shade600
            )

            // Goal Progress
            MoneyStatCard(
                icon: "target",
                iconGradient: [Color.fromHex("C9A961"), Color.fromHex("EAB308")],
                title: "Goal Progress",
                value: "\(Int(goalProgress * 100))%",
                subtitle: "Target reached",
                badge: "\(Int(goalProgress * 100))%",
                badgeColor: Color.fromHex("3B82F6")
            )
        }
    }
}

struct MoneyStatCard: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let value: String
    let subtitle: String
    let badge: String
    let badgeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: iconGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Badge
                Text(badge)
                    .font(Typography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(badgeColor.opacity(0.15))
                    )
            }

            Text(title)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            Text(value)
                .font(Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)

            Text(subtitle)
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textTertiary)
        }
        .glassPanel()
    }
}

// MARK: - Charts Section

struct MoneyManagementChartsSection: View {
    let contributions: [GiftOrOwed]
    @Binding var selectedTimeRange: TimeRange

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Contribution Timeline (2/3 width)
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Contribution Timeline")
                            .font(Typography.heading)
                            .foregroundColor(SemanticColors.textPrimary)
                        Text("Monthly tracking of contributions received")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }

                    Spacer()

                    // Time range picker
                    HStack(spacing: Spacing.xs) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                selectedTimeRange = range
                            } label: {
                                Text(range.rawValue)
                                    .font(Typography.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        selectedTimeRange == range
                                            ? BlushPink.shade500
                                            : Color.clear
                                    )
                                    .foregroundColor(
                                        selectedTimeRange == range
                                            ? .white
                                            : SemanticColors.textSecondary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ContributionTimelineChart(contributions: contributions)
                    .frame(height: 280)
            }
            .glassPanel()
            .frame(maxWidth: .infinity)

            // Contribution Types Pie Chart (1/3 width)
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Contribution Types")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Distribution by category")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                ContributionTypesChart(contributions: contributions)
                    .frame(height: 280)
            }
            .glassPanel()
            .frame(width: 320)
        }
    }
}

struct ContributionTimelineChart: View {
    let contributions: [GiftOrOwed]

    private var monthlyData: [(month: String, amount: Double)] {
        let calendar = Calendar.current
        var monthlyTotals: [String: Double] = [:]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        for contribution in contributions where contribution.status == .confirmed || contribution.status == .received {
            let monthKey = dateFormatter.string(from: contribution.createdAt)
            monthlyTotals[monthKey, default: 0] += contribution.amount
        }

        // Get last 6 months
        let now = Date()
        var result: [(month: String, amount: Double)] = []
        var runningTotal: Double = 0

        for i in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                let monthKey = dateFormatter.string(from: date)
                runningTotal += monthlyTotals[monthKey] ?? 0
                result.append((monthKey, runningTotal))
            }
        }

        return result
    }

    var body: some View {
        Chart {
            ForEach(monthlyData, id: \.month) { data in
                AreaMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [BlushPink.shade400.opacity(0.3), BlushPink.shade400.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(BlushPink.shade500)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.abbreviated)
                            .font(Typography.caption2)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let month = value.as(String.self) {
                        Text(month.components(separatedBy: " ").first ?? month)
                            .font(Typography.caption2)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }
        }
    }
}

struct ContributionTypesChart: View {
    let contributions: [GiftOrOwed]

    private var typeData: [(type: String, amount: Double, color: Color)] {
        var cashAmount: Double = 0
        var giftAmount: Double = 0
        var pledgedAmount: Double = 0

        for contribution in contributions {
            switch contribution.status {
            case .confirmed, .received:
                if contribution.type == .giftReceived {
                    giftAmount += contribution.amount
                } else {
                    cashAmount += contribution.amount
                }
            case .pending:
                pledgedAmount += contribution.amount
            }
        }

        return [
            ("Cash", cashAmount, SageGreen.shade500),
            ("Gifts", giftAmount, BlushPink.shade500),
            ("Pledged", pledgedAmount, Terracotta.shade500)
        ].filter { $0.1 > 0 }
    }

    var body: some View {
        Chart {
            ForEach(typeData, id: \.type) { data in
                SectorMark(
                    angle: .value("Amount", data.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(data.color)
                .cornerRadius(4)
            }
        }
        .chartLegend(position: .bottom, spacing: Spacing.md)
    }
}

// MARK: - Goal Tracker Banner

struct MoneyManagementGoalTracker: View {
    let currentAmount: Double
    let goalAmount: Double
    let contributorCount: Int
    let daysToWedding: Int
    let averageContribution: Double
    let giftItemCount: Int

    private var progress: Double {
        guard goalAmount > 0 else { return 0 }
        return min(currentAmount / goalAmount, 1.0)
    }

    private var remaining: Double {
        max(0, goalAmount - currentAmount)
    }

    var body: some View {
        HStack(spacing: Spacing.huge) {
            // Left side - Progress info
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Wedding Fund Goal")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("We're getting closer to making our dream wedding a reality! Thank you for your generous support.")
                    .font(Typography.bodyRegular)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)

                VStack(spacing: Spacing.md) {
                    HStack {
                        Text("Current: \(currentAmount.currencyFormatted)")
                            .font(Typography.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Goal: \(goalAmount.currencyFormatted)")
                            .font(Typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 16)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: geometry.size.width * progress, height: 16)
                        }
                    }
                    .frame(height: 16)

                    HStack {
                        Text("\(Int(progress * 100))% Complete")
                            .font(Typography.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(remaining.currencyFormatted) to go")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)

            // Right side - Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                GoalStatCard(icon: "person.2.fill", value: "\(contributorCount)", label: "Contributors")
                GoalStatCard(icon: "calendar", value: "\(daysToWedding)", label: "Days to Wedding")
                GoalStatCard(icon: "chart.line.uptrend.xyaxis", value: averageContribution.currencyFormatted, label: "Avg. Contribution")
                GoalStatCard(icon: "star.fill", value: "\(giftItemCount)", label: "Gift Items")
            }
            .frame(width: 340)
        }
        .padding(Spacing.xxl)
        .background(
            LinearGradient(
                colors: [BlushPink.shade500, Color.fromHex("C9A961")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
    }
}

struct GoalStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Contributions Section

struct MoneyManagementContributionsSection: View {
    let contributions: [GiftOrOwed]
    let topContributors: [(name: String, amount: Double, relationship: String?)]
    let totalPledged: Double
    let pendingCount: Int

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Recent Contributions Table (2/3 width)
            RecentContributionsTable(contributions: Array(contributions.prefix(6)))

            // Sidebar (1/3 width)
            VStack(spacing: Spacing.lg) {
                TopContributorsCard(contributors: topContributors)
                PledgeSummaryCard(totalPledged: totalPledged, pendingCount: pendingCount)
            }
            .frame(width: 320)
        }
    }
}

struct RecentContributionsTable: View {
    let contributions: [GiftOrOwed]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Recent Contributions")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Latest received contributions and gifts")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                Button {
                    // Filter action
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filter")
                    }
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(BlushPink.shade600)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(BlushPink.shade100)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)

            Divider()

            // Table Header
            HStack {
                Text("Contributor")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Type")
                    .frame(width: 100, alignment: .leading)
                Text("Amount")
                    .frame(width: 100, alignment: .leading)
                Text("Date")
                    .frame(width: 120, alignment: .leading)
                Text("Status")
                    .frame(width: 100, alignment: .leading)
            }
            .font(Typography.caption2)
            .fontWeight(.semibold)
            .foregroundColor(SemanticColors.textSecondary)
            .textCase(.uppercase)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.gray.opacity(0.05))

            // Table Rows
            ForEach(contributions) { contribution in
                ContributionRow(contribution: contribution)
            }

            Divider()

            // Footer
            HStack {
                Text("Showing \(contributions.count) contributions")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Button {
                    // View all
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text("View All")
                        Image(systemName: "arrow.right")
                    }
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(BlushPink.shade600)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
        }
        .glassPanel(padding: 0)
    }
}

struct ContributionRow: View {
    let contribution: GiftOrOwed

    @State private var isHovered = false

    var body: some View {
        HStack {
            // Contributor
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BlushPink.shade300, BlushPink.shade500],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(contribution.fromPerson?.prefix(1) ?? "?"))
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(contribution.fromPerson ?? "Anonymous")
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)

                    if let description = contribution.description {
                        Text(description)
                            .font(Typography.caption2)
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Type
            ContributionTypeBadge(type: contribution.type)
                .frame(width: 100, alignment: .leading)

            // Amount
            Text(contribution.amount.currencyFormatted)
                .font(Typography.bodySmall)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)
                .frame(width: 100, alignment: .leading)

            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(DateFormatting.formatDateMedium(contribution.createdAt, timezone: .current))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(DateFormatting.formatRelativeDate(contribution.createdAt, timezone: .current))
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .frame(width: 120, alignment: .leading)

            // Status
            ContributionStatusBadge(status: contribution.status)
                .frame(width: 100, alignment: .leading)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(isHovered ? Color.gray.opacity(0.05) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ContributionTypeBadge: View {
    let type: GiftOrOwed.GiftOrOwedType

    private var config: (icon: String, text: String, color: Color) {
        switch type {
        case .giftReceived:
            return ("gift.fill", "Gift", SoftLavender.shade600)
        case .moneyOwed:
            return ("banknote.fill", "Cash", SageGreen.shade600)
        case .contribution:
            return ("dollarsign.circle.fill", "Cash", SageGreen.shade600)
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: config.icon)
                .font(.system(size: 10))
            Text(config.text)
                .font(Typography.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(config.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(config.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct ContributionStatusBadge: View {
    let status: GiftOrOwed.GiftOrOwedStatus

    private var config: (icon: String, text: String, color: Color) {
        switch status {
        case .received, .confirmed:
            return ("checkmark.circle.fill", "Received", SageGreen.shade600)
        case .pending:
            return ("clock.fill", "Pending", Terracotta.shade600)
        }
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: config.icon)
                .font(.system(size: 10))
            Text(config.text)
                .font(Typography.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(config.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(config.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct TopContributorsCard: View {
    let contributors: [(name: String, amount: Double, relationship: String?)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Top Contributors")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                Text("Highest contributions")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(Array(contributors.enumerated()), id: \.element.name) { index, contributor in
                    HStack(spacing: Spacing.md) {
                        // Rank badge
                        RankBadge(rank: index + 1)

                        // Avatar
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [BlushPink.shade300, BlushPink.shade500],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(contributor.name.prefix(1)))
                                    .font(Typography.bodyRegular)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )

                        // Name and relationship
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contributor.name)
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(SemanticColors.textPrimary)

                            if let relationship = contributor.relationship {
                                Text(relationship)
                                    .font(Typography.caption2)
                                    .foregroundColor(SemanticColors.textTertiary)
                            }
                        }

                        Spacer()

                        // Amount
                        Text(contributor.amount.currencyFormatted)
                            .font(Typography.bodySmall)
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                }
            }
        }
        .glassPanel()
    }
}

struct RankBadge: View {
    let rank: Int

    private var gradient: [Color] {
        switch rank {
        case 1: return [Color.fromHex("F59E0B"), Color.fromHex("D97706")]
        case 2: return [Color.gray.opacity(0.6), Color.gray.opacity(0.8)]
        case 3: return [Color.fromHex("F97316"), Color.fromHex("EA580C")]
        default: return [Color.gray.opacity(0.3), Color.gray.opacity(0.4)]
        }
    }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 28, height: 28)
            .overlay(
                Text("\(rank)")
                    .font(Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
    }
}

struct PledgeSummaryCard: View {
    let totalPledged: Double
    let pendingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "handshake.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)

                Spacer()

                Text("\(pendingCount) Pending")
                    .font(Typography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }

            Text(totalPledged.currencyFormatted)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("Total Pledged Amount")
                .font(Typography.caption)
                .foregroundColor(.white.opacity(0.9))

            Button {
                // View pledges
            } label: {
                Text("View Pledges")
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SageGreen.shade700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [SageGreen.shade500, SageGreen.shade700],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
    }
}

// MARK: - Gift Registry

struct MoneyManagementGiftRegistry: View {
    let gifts: [GiftReceived]
    let onAddItem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Gift Registry Items")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Physical gifts received from our registry")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                Button {
                    onAddItem()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Add Item")
                    }
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(BlushPink.shade600)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(BlushPink.shade100)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)

            Divider()

            // Gift Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(gifts) { gift in
                    GiftRegistryItemCard(gift: gift)
                }
            }
            .padding(Spacing.lg)
        }
        .glassPanel(padding: 0)
    }
}

struct GiftRegistryItemCard: View {
    let gift: GiftReceived

    @State private var isHovered = false

    private var iconName: String {
        switch gift.giftType {
        case .gift: return "gift.fill"
        case .giftCard: return "creditcard.fill"
        default: return "shippingbox.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.gray.opacity(0.1))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 32))
                        .foregroundColor(Color.gray.opacity(0.4))
                )

            Text(gift.notes ?? "Gift Item")
                .font(Typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(1)

            Text("From \(gift.fromPerson)")
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textTertiary)

            HStack {
                Text(gift.amount.currencyFormatted)
                    .font(Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(BlushPink.shade600)

                Spacer()

                Text("Received")
                    .font(Typography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(SageGreen.shade600)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(SageGreen.shade100)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: isHovered ? Color.black.opacity(0.1) : Color.clear, radius: 8, x: 0, y: 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Pending Pledges

struct MoneyManagementPendingPledges: View {
    let pledges: [GiftOrOwed]
    let totalPledged: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Pending Pledges")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Contributions committed but not yet received")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(totalPledged.currencyFormatted)
                        .font(Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Terracotta.shade600)
                    Text("Total pledged")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }
            .padding(Spacing.lg)

            Divider()

            // Pledges Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(pledges) { pledge in
                    PledgeCard(pledge: pledge)
                }
            }
            .padding(Spacing.lg)
        }
        .glassPanel(padding: 0)
    }
}

struct PledgeCard: View {
    let pledge: GiftOrOwed

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Terracotta.shade300, Terracotta.shade500],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(pledge.fromPerson?.prefix(1) ?? "?"))
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Terracotta.shade300, lineWidth: 2)
                    )

                Spacer()

                Text("Pending")
                    .font(Typography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Terracotta.shade600)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Terracotta.shade100)
                    .clipShape(Capsule())
            }

            Text(pledge.fromPerson ?? "Anonymous")
                .font(Typography.bodySmall)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)

            if let description = pledge.description {
                Text(description)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textTertiary)
            }

            HStack {
                Text(pledge.amount.currencyFormatted)
                    .font(Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Terracotta.shade600)

                Spacer()

                Button {
                    // Remind action
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                        Text("Remind")
                    }
                    .font(Typography.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Terracotta.shade600)
                }
                .buttonStyle(.plain)
            }

            if let expectedDate = pledge.expectedDate {
                Text("Pledged: \(DateFormatting.formatDateMedium(expectedDate, timezone: .current))")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textTertiary)
            }
        }
        .padding(Spacing.lg)
        .background(Terracotta.shade50.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Terracotta.shade200, lineWidth: 1)
        )
    }
}

// MARK: - Insights Section

struct MoneyManagementInsights: View {
    let contributions: [GiftOrOwed]

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Contribution by Relationship
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Contribution by Relationship")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("How different groups contributed")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                RelationshipChart(contributions: contributions)
                    .frame(height: 260)
            }
            .glassPanel()

            // Monthly Trend
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Monthly Contribution Trend")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("Growth over the past 6 months")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                MonthlyTrendChart(contributions: contributions)
                    .frame(height: 260)
            }
            .glassPanel()
        }
    }
}

struct RelationshipChart: View {
    let contributions: [GiftOrOwed]

    private var relationshipData: [(relationship: String, amount: Double, color: Color)] {
        // Group by description (which often contains relationship info)
        var totals: [String: Double] = [:]

        for contribution in contributions where contribution.status == .confirmed || contribution.status == .received {
            let relationship = contribution.description ?? "Other"
            totals[relationship, default: 0] += contribution.amount
        }

        let colors: [Color] = [BlushPink.shade500, Color.fromHex("C9A961"), SageGreen.shade500, Terracotta.shade500, SoftLavender.shade500]

        return totals.sorted { $0.value > $1.value }
            .prefix(5)
            .enumerated()
            .map { (index, item) in
                (item.key, item.value, colors[index % colors.count])
            }
    }

    var body: some View {
        Chart {
            ForEach(relationshipData, id: \.relationship) { data in
                BarMark(
                    x: .value("Relationship", data.relationship),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(data.color)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.abbreviated)
                            .font(Typography.caption2)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }
        }
    }
}

struct MonthlyTrendChart: View {
    let contributions: [GiftOrOwed]

    private var monthlyData: [(month: String, amount: Double)] {
        let calendar = Calendar.current
        var monthlyTotals: [String: Double] = [:]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"

        for contribution in contributions where contribution.status == .confirmed || contribution.status == .received {
            let monthKey = dateFormatter.string(from: contribution.createdAt)
            monthlyTotals[monthKey, default: 0] += contribution.amount
        }

        // Get last 6 months
        let now = Date()
        var result: [(month: String, amount: Double)] = []

        for i in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                let monthKey = dateFormatter.string(from: date)
                result.append((monthKey, monthlyTotals[monthKey] ?? 0))
            }
        }

        return result
    }

    var body: some View {
        Chart {
            ForEach(monthlyData, id: \.month) { data in
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(Color.fromHex("C9A961"))
                .lineStyle(StrokeStyle(lineWidth: 3))

                PointMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(Color.fromHex("C9A961"))
                .symbolSize(64)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount.abbreviated)
                            .font(Typography.caption2)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Thank You Section

struct MoneyManagementThankYouSection: View {
    let sentCount: Int
    let pendingCount: Int

    private var responseRate: Int {
        let total = sentCount + pendingCount
        guard total > 0 else { return 100 }
        return Int(Double(sentCount) / Double(total) * 100)
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Heart icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [BlushPink.shade500, Color.fromHex("C9A961")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )

            Text("Thank You Messages")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(SemanticColors.textPrimary)

            Text("We're incredibly grateful for everyone's generous support. Your contributions are helping us create the wedding of our dreams!")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            // Stats
            HStack(spacing: Spacing.lg) {
                ThankYouStatCard(
                    icon: "envelope.fill",
                    iconColor: BlushPink.shade600,
                    value: "\(sentCount)",
                    label: "Thank You Sent"
                )

                ThankYouStatCard(
                    icon: "clock.fill",
                    iconColor: Terracotta.shade500,
                    value: "\(pendingCount)",
                    label: "Pending Notes"
                )

                ThankYouStatCard(
                    icon: "checkmark.circle.fill",
                    iconColor: SageGreen.shade500,
                    value: "\(responseRate)%",
                    label: "Response Rate"
                )
            }

            Button {
                // Send thank you notes
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "pencil.line")
                    Text("Send Thank You Notes")
                }
                .font(Typography.bodyRegular)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
                .background(BlushPink.shade500)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .shadow(color: BlushPink.shade500.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    SoftLavender.shade100,
                    BlushPink.shade100,
                    BlushPink.shade200
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
    }
}

struct ThankYouStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            Text(value)
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Add Contribution Modal (Placeholder)

struct AddContributionModal: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Text("Add Contribution")
                .font(Typography.title2)
                .fontWeight(.bold)

            Text("Coming soon...")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Spacing.xxl)
        .frame(width: 400, height: 300)
    }
}

// MARK: - Currency Formatting Extension

private extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "$0"
    }

    var abbreviated: String {
        if self >= 1000 {
            return String(format: "$%.1fK", self / 1000)
        }
        return String(format: "$%.0f", self)
    }
}
