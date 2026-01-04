//
//  DashboardViewV7.swift
//  I Do Blueprint
//
//  V7 Dashboard with glassmorphism design
//  Features:
//  - Mesh gradient background with animated color blobs
//  - Frosted glass panels with blur effects
//  - Modern Apple design language
//  - Real-time countdown with live seconds
//  - Responsive grid layout
//

import SwiftUI
import Combine
import Sentry

struct DashboardViewV7: View {
    @Environment(\.appStores) private var appStores
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator
    
    // Preview control
    private let previewForceLoading: Bool?
    
    // View Model
    @StateObject private var viewModel: DashboardViewModel
    
    // Live countdown timer
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Convenience accessors for stores
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var guestStore: GuestStoreV2 { appStores.guest }
    private var taskStore: TaskStoreV2 { appStores.task }

    // Adaptive grid for main content cards
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 300), spacing: Spacing.lg, alignment: .top)
    ]

    // Fixed 3-column grid for metric cards
    private let metricColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: Spacing.lg, alignment: .top),
        count: 3
    )

    init(previewForceLoading: Bool? = nil, appStores: AppStores = .shared) {
        self.previewForceLoading = previewForceLoading
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            budgetStore: appStores.budget,
            vendorStore: appStores.vendor,
            guestStore: appStores.guest,
            taskStore: appStores.task,
            settingsStore: appStores.settings
        ))
    }

    var body: some View {
        let effectiveIsLoading = previewForceLoading ?? viewModel.isLoading
        let effectiveHasLoaded = (previewForceLoading == nil) ? viewModel.hasLoaded : !(previewForceLoading!)

        return NavigationStack {
            ZStack {
                // MARK: - Mesh Gradient Background
                MeshGradientBackgroundV7()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // MARK: - Header
                        DashboardHeaderV7()
                            .padding(.horizontal, Spacing.xxl)

                        // MARK: - Hero Banner with Countdown
                        Group {
                            if effectiveHasLoaded {
                                HeroBannerV7(
                                    weddingDate: viewModel.weddingDate,
                                    partner1Name: viewModel.partner1DisplayName,
                                    partner2Name: viewModel.partner2DisplayName,
                                    currentTime: currentTime
                                )
                            } else {
                                DashboardHeroSkeleton()
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)

                        // MARK: - Metric Cards Row (RSVPs, Vendors, Budget)
                        LazyVGrid(columns: metricColumns, alignment: .center, spacing: Spacing.lg) {
                            if effectiveHasLoaded {
                                RSVPMetricCardV7(
                                    confirmed: viewModel.rsvpYesCount,
                                    pending: viewModel.rsvpPendingCount,
                                    total: viewModel.totalGuests
                                )
                                VendorMetricCardV7(
                                    booked: viewModel.vendorsBookedCount,
                                    total: viewModel.totalVendors
                                )
                                BudgetMetricCardV7(
                                    spent: viewModel.totalPaid,
                                    total: viewModel.totalBudget,
                                    percentage: viewModel.budgetPercentage
                                )
                            } else {
                                MetricCardSkeleton()
                                MetricCardSkeleton()
                                MetricCardSkeleton()
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)

                        // MARK: - Main Content Grid
                        LazyVGrid(columns: columns, alignment: .center, spacing: Spacing.lg) {
                            if effectiveHasLoaded {
                                // Budget Overview Card
                                BudgetOverviewCardV7(
                                    totalBudget: viewModel.totalBudget,
                                    totalSpent: viewModel.totalPaid
                                )
                                
                                // Task Manager Card
                                TaskManagerCardV7(store: taskStore)
                                
                                // Guest Responses Card
                                GuestResponsesCardV7(store: guestStore)
                                    .environmentObject(settingsStore)
                                    .environmentObject(budgetStore)
                                    .environmentObject(coordinator)
                                
                                // Payments Due Card
                                PaymentsDueCardV7(store: vendorStore)
                                
                                // Recent Responses Card
                                RecentResponsesCardV7(store: guestStore)
                                
                                // Vendor List Card
                                VendorListCardV7(store: vendorStore)
                            } else {
                                DashboardBudgetCardSkeleton()
                                DashboardTasksCardSkeleton()
                                DashboardGuestsCardSkeleton()
                                DashboardVendorsCardSkeleton()
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)
                    }
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: Spacing.md) {
                        if effectiveIsLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        Button {
                            Task { await viewModel.loadDashboardData() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SemanticColors.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibleActionButton(
                            label: "Refresh dashboard",
                            hint: "Reload all dashboard data"
                        )
                    }
                }
            }
        }
        .task {
            if !viewModel.hasLoaded {
                await viewModel.loadDashboardData()
            }
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
}

// MARK: - Mesh Gradient Background

struct MeshGradientBackgroundV7: View {
    var body: some View {
        ZStack {
            // Base color
            Color.fromHex("F3F4F6")
            
            // Animated color blobs
            GeometryReader { geometry in
                ZStack {
                    // Pink blob - top left
                    Circle()
                        .fill(AppGradients.softPink.opacity(0.6))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.1)
                    
                    // Sage blob - bottom right
                    Circle()
                        .fill(AppGradients.sageGreen.opacity(0.6))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.8)
                    
                    // Cream blob - center
                    Circle()
                        .fill(Color.fromHex("F8E8D0").opacity(0.5))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.4)
                    
                    // Pink blob - bottom left
                    Circle()
                        .fill(AppGradients.softPink.opacity(0.4))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.9)
                }
            }
        }
    }
}

// MARK: - Dashboard Header

struct DashboardHeaderV7: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Wedding Planning")
                    .font(Typography.title2)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("Wedding Planner - Dec 11, 2026")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.md) {
                // Import Button
                Button {
                    // Import action
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                    }
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                }
                .buttonStyle(.plain)
                .glassPanel(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
                
                // Export Button
                Button {
                    // Export action
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                }
                .buttonStyle(.plain)
                .glassPanel(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
                
                // Add Guest Button
                Button {
                    // Add guest action
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Add Guest")
                    }
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(AppGradients.weddingPink)
                    )
                    .shadow(color: AppGradients.weddingPink.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Hero Banner with Live Countdown

struct HeroBannerV7: View {
    let weddingDate: Date?
    let partner1Name: String
    let partner2Name: String
    let currentTime: Date
    
    private var weddingTitle: String {
        if !partner1Name.isEmpty && !partner2Name.isEmpty {
            return "\(partner1Name) & \(partner2Name)'s Wedding"
        } else if !partner1Name.isEmpty {
            return "\(partner1Name)'s Wedding"
        } else if !partner2Name.isEmpty {
            return "\(partner2Name)'s Wedding"
        } else {
            return "Our Wedding"
        }
    }
    
    private var countdown: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        guard let weddingDate = weddingDate else {
            return (0, 0, 0, 0)
        }
        let interval = weddingDate.timeIntervalSince(currentTime)
        guard interval > 0 else { return (0, 0, 0, 0) }
        
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        return (days, hours, minutes, seconds)
    }
    
    private var formattedDate: String {
        guard let date = weddingDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            // Left side - Wedding info
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(weddingTitle)
                    .font(Typography.title2)
                    .foregroundColor(SemanticColors.textPrimary)
                
                if weddingDate != nil {
                    Text(formattedDate)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Right side - Countdown
            HStack(spacing: Spacing.xl) {
                // Days
                VStack(spacing: Spacing.xxs) {
                    Text("\(countdown.days)")
                        .font(Typography.displayMedium)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("DAYS")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                        .tracking(1.2)
                }
                
                // Divider
                Rectangle()
                    .fill(SemanticColors.borderLight)
                    .frame(width: 1, height: 40)
                
                // Time components
                HStack(spacing: Spacing.lg) {
                    CountdownUnitV7(value: countdown.hours, label: "Hours")
                    Text(":")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textSecondary)
                    CountdownUnitV7(value: countdown.minutes, label: "Minutes")
                    Text(":")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textSecondary)
                    CountdownUnitV7(value: countdown.seconds, label: "Seconds")
                }
            }
        }
        .padding(Spacing.xxl)
        .glassPanel(cornerRadius: CornerRadius.xxl, padding: 0)
        .overlay(
            // Decorative pink circle
            Circle()
                .fill(BlushPink.shade100.opacity(0.5))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 100, y: -50),
            alignment: .topTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
    }
}

struct CountdownUnitV7: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(String(format: "%02d", value))
                .font(Typography.numberMedium)
                .foregroundColor(SemanticColors.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(SemanticColors.textSecondary)
                .textCase(.uppercase)
        }
    }
}

// MARK: - Metric Cards

struct RSVPMetricCardV7: View {
    let confirmed: Int
    let pending: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(confirmed) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Total Responses")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text("\(confirmed + pending) RSVP")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textPrimary)
                }
                
                Spacer()
                
                NativeIconBadge(
                    systemName: "person.2.fill",
                    color: AppGradients.weddingPink,
                    size: 40
                )
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppGradients.weddingPink)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(AppGradients.weddingPink)
                        .frame(width: 6, height: 6)
                    Text("Confirmed: \(confirmed)")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Text("Pending: \(pending)")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
        .glassPanel()
    }
}

struct VendorMetricCardV7: View {
    let booked: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(booked) / Double(total)
    }
    
    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(booked) / Double(total)) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Vendors Booked")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text("\(booked)")
                            .font(Typography.title3)
                            .foregroundColor(SemanticColors.textPrimary)
                        Text("/ \(total)")
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }
                
                Spacer()
                
                NativeIconBadge(
                    systemName: "wrench.and.screwdriver.fill",
                    color: AppGradients.sageDark,
                    size: 40
                )
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppGradients.sageDark)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(percentage)% Completed")
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .glassPanel()
    }
}

struct BudgetMetricCardV7: View {
    let spent: Double
    let total: Double
    let percentage: Double
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(spent / total, 1.0)
    }
    
    private var formattedSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: spent)) ?? "$0"
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "$0"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Budget Used")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(formattedSpent)
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textPrimary)
                }
                
                Spacer()
                
                NativeIconBadge(
                    systemName: "dollarsign.circle.fill",
                    color: AppGradients.sageDark,
                    size: 40
                )
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppGradients.sageDark)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("Total Budget: \(formattedTotal)")
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .glassPanel()
    }
}

// MARK: - Budget Overview Card

struct BudgetOverviewCardV7: View {
    let totalBudget: Double
    let totalSpent: Double
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalBudget)) ?? "$0"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Budget Overview")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Text(formattedTotal)
                    .font(Typography.title3)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            VStack(spacing: Spacing.lg) {
                // Progress bar 1
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppGradients.sageDark)
                            .frame(width: geometry.size.width * 0.65, height: 8)
                    }
                }
                .frame(height: 8)
                
                // Progress bar 2
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: geometry.size.width * 0.35, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            HStack {
                Text("$7,150")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
                
                Spacer()
                
                Text("$3.7M")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .glassPanel()
    }
}

// MARK: - Task Manager Card

struct TaskManagerCardV7: View {
    @ObservedObject var store: TaskStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Task Manager")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // View all action
                }
                .font(Typography.caption)
                .foregroundColor(AppGradients.weddingPink)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                TaskRowV7(title: "Send invites to All Guests", isCompleted: false)
                TaskRowV7(title: "Check Confirmants", isCompleted: true)
                TaskRowV7(title: "Pending Emails", isCompleted: true)
                TaskRowV7(title: "Review Task Manager", isCompleted: false)
                TaskRowV7(title: "Guest Management", isCompleted: false)
            }
        }
        .glassPanel()
    }
}

struct TaskRowV7: View {
    let title: String
    let isCompleted: Bool
    @State private var checked: Bool
    
    init(title: String, isCompleted: Bool) {
        self.title = title
        self.isCompleted = isCompleted
        self._checked = State(initialValue: isCompleted)
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
                checked.toggle()
            } label: {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(checked ? AppGradients.weddingPink : SemanticColors.textTertiary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            
            Text(title)
                .font(Typography.bodySmall)
                .foregroundColor(checked ? AppGradients.weddingPink : SemanticColors.textPrimary)
                .strikethrough(checked, color: AppGradients.weddingPink)
        }
    }
}

// MARK: - Guest Responses Card

struct GuestResponsesCardV7: View {
    @ObservedObject var store: GuestStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Guest Responses")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            VStack(spacing: Spacing.md) {
                GuestRowV7(
                    initials: "SJ",
                    name: "Sarah Jenkins",
                    invitedBy: "Invited by Bride",
                    status: .confirmed
                )
                GuestRowV7(
                    initials: "MR",
                    name: "Michael Ross",
                    invitedBy: "Invited by Groom",
                    status: .pending
                )
                GuestRowV7(
                    initials: "DM",
                    name: "David Miller",
                    invitedBy: "Invited by Bride",
                    status: .declined
                )
            }
        }
        .glassPanel()
    }
}

enum GuestStatusV7 {
    case confirmed, pending, declined
    
    var color: Color {
        switch self {
        case .confirmed: return AppGradients.sageDark
        case .pending: return SoftLavender.shade500
        case .declined: return Terracotta.shade500
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .confirmed: return AppGradients.sageGreen.opacity(0.5)
        case .pending: return SoftLavender.shade100
        case .declined: return Terracotta.shade100
        }
    }
    
    var text: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .pending: return "Pending"
        case .declined: return "Declined"
        }
    }
}

struct GuestRowV7: View {
    let initials: String
    let name: String
    let invitedBy: String
    let status: GuestStatusV7
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initials)
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(SemanticColors.textSecondary)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name)
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(invitedBy)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            // Status badge
            Text(status.text.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(status.color)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(status.backgroundColor)
                )
        }
    }
}

// MARK: - Payments Due Card

struct PaymentsDueCardV7: View {
    @ObservedObject var store: VendorStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Payments Due (Feb)")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Button {
                    // Add payment
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add")
                            .font(Typography.caption2)
                    }
                    .foregroundColor(SemanticColors.textPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.white.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 0) {
                PaymentRowV7(title: "Floral Arrangements", amount: "$0.00", isHighlighted: false)
                Divider().opacity(0.5)
                PaymentRowV7(title: "Catering Deposit", amount: "$0.00", isHighlighted: false)
                Divider().opacity(0.5)
                PaymentRowV7(title: "DJ & Music", amount: "$20.00", isHighlighted: true)
            }
        }
        .glassPanel()
    }
}

struct PaymentRowV7: View {
    let title: String
    let amount: String
    let isHighlighted: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textPrimary)
            
            Spacer()
            
            Text(amount)
                .font(Typography.bodySmall)
                .fontWeight(.bold)
                .foregroundColor(isHighlighted ? AppGradients.weddingPink : SemanticColors.textPrimary)
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Recent Responses Card

struct RecentResponsesCardV7: View {
    @ObservedObject var store: GuestStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Recent Responses")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "clock")
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                ActivityRowV7(
                    color: AppGradients.sageDark,
                    text: "Emily White confirmed attendance.",
                    time: "2 hours ago"
                )
                ActivityRowV7(
                    color: SoftLavender.shade400,
                    text: "John Doe viewed the invitation.",
                    time: "5 hours ago"
                )
                ActivityRowV7(
                    color: Terracotta.shade400,
                    text: "Alice Blue declined.",
                    time: "1 day ago"
                )
            }
        }
        .glassPanel()
    }
}

struct ActivityRowV7: View {
    let color: Color
    let text: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(text)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(time)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)
            }
        }
    }
}

// MARK: - Vendor List Card

struct VendorListCardV7: View {
    @ObservedObject var store: VendorStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Vendor List")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Button("Manage") {
                    // Manage action
                }
                .font(Typography.caption)
                .foregroundColor(AppGradients.weddingPink)
            }
            
            VStack(spacing: Spacing.md) {
                VendorRowV7(
                    icon: "camera.fill",
                    iconColor: Color.blue,
                    iconBackground: Color.blue.opacity(0.1),
                    name: "Vendor Smith",
                    category: "Photography",
                    status: .booked
                )
                VendorRowV7(
                    icon: "music.note",
                    iconColor: AppGradients.weddingPink,
                    iconBackground: BlushPink.shade100,
                    name: "Louis Sitt",
                    category: "Music/Band",
                    status: .pending
                )
                VendorRowV7(
                    icon: "fork.knife",
                    iconColor: Terracotta.shade500,
                    iconBackground: Terracotta.shade100,
                    name: "Gourmet Co.",
                    category: "Catering",
                    status: .declined
                )
            }
        }
        .glassPanel()
    }
}

enum VendorStatusV7 {
    case booked, pending, declined
    
    var icon: String {
        switch self {
        case .booked: return "checkmark"
        case .pending: return "hourglass"
        case .declined: return "xmark"
        }
    }
    
    var color: Color {
        switch self {
        case .booked: return AppGradients.sageDark
        case .pending: return SoftLavender.shade600
        case .declined: return Terracotta.shade600
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .booked: return AppGradients.sageGreen.opacity(0.5)
        case .pending: return SoftLavender.shade100
        case .declined: return Terracotta.shade100
        }
    }
}

struct VendorRowV7: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let name: String
    let category: String
    let status: VendorStatusV7
    
    var body: some View {
        HStack {
            // Icon
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(iconBackground)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name)
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(category)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            // Status button
            Button {
                // Status action
            } label: {
                Circle()
                    .fill(status.backgroundColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: status.icon)
                            .font(.system(size: 12))
                            .foregroundColor(status.color)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview("Dashboard V7 - Light") {
    DashboardViewV7()
        .environmentObject(AppStores.shared)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1400, height: 900)
        .preferredColorScheme(.light)
}

#Preview("Dashboard V7 - Dark") {
    DashboardViewV7()
        .environmentObject(AppStores.shared)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1400, height: 900)
        .preferredColorScheme(.dark)
}

#Preview("Dashboard V7 - Loading") {
    DashboardViewV7(previewForceLoading: true)
        .environmentObject(AppStores.shared)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1400, height: 900)
}
