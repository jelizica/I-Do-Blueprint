//
//  DashboardViewV3.swift
//  I Do Blueprint
//
//  Modern comprehensive dashboard with visual intrigue
//

import SwiftUI

struct DashboardViewV3: View {
    private let logger = AppLogger.ui
    @EnvironmentObject private var appStores: AppStores

    // Convenience accessors
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var guestStore: GuestStoreV2 { appStores.guest }
    private var taskStore: TaskStoreV2 { appStores.task }
    private var settingsStore: SettingsStoreV2 { appStores.settings }
    private var timelineStore: TimelineStoreV2 { appStores.timeline }
    private var documentStore: DocumentStoreV2 { appStores.document }

    @State private var isLoading = false
    @State private var hasLoaded = false

    // Quick action modals
    @State private var showingTaskModal = false
    @State private var showingNoteModal = false
    @State private var showingEventModal = false
    @State private var showingGuestModal = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.fromHex("F8F9FA"),
                        Color.fromHex("E9ECEF")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Quick Actions Bar
                        QuickActionsBar(
                            showingTaskModal: $showingTaskModal,
                            showingNoteModal: $showingNoteModal,
                            showingEventModal: $showingEventModal,
                            showingGuestModal: $showingGuestModal
                        )

                        // Hero Section
                        WeddingCountdownHero(
                            weddingDate: weddingDate,
                            daysUntil: daysUntilWedding
                        )

                        // Key Metrics Row
                        if hasLoaded {
                            HStack(spacing: Spacing.md) {
                                MetricCard(
                                    title: "Budget Used",
                                    value: budgetStore.percentagePaid,
                                    format: .percentage,
                                    icon: "dollarsign.circle.fill",
                                    color: budgetColor
                                )

                                let guests = guestStore.guests
                                let yesCount = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count

                                MetricCard(
                                    title: "Guests RSVP'd",
                                    value: Double(yesCount),
                                    total: Double(guests.count),
                                    format: .fraction,
                                    icon: "person.2.fill",
                                    color: AppColors.Guest.confirmed
                                )

                                let completedCount = taskStore.tasks.filter { $0.status == .completed }.count

                                MetricCard(
                                    title: "Tasks Done",
                                    value: Double(completedCount),
                                    total: Double(taskStore.tasks.count),
                                    format: .fraction,
                                    icon: "checkmark.circle.fill",
                                    color: SemanticColors.success
                                )

                                let bookedCount = vendorStore.vendors.filter { $0.isBooked == true }.count

                                MetricCard(
                                    title: "Vendors Booked",
                                    value: Double(bookedCount),
                                    total: Double(vendorStore.vendors.count),
                                    format: .fraction,
                                    icon: "briefcase.fill",
                                    color: AppColors.Vendor.booked
                                )
                            }
                        }

                        // Overview Content
                        if hasLoaded {
                            VStack(spacing: Spacing.lg) {
                                // Budget & RSVP Row
                                HStack(spacing: Spacing.lg) {
                                    BudgetOverviewCard(store: budgetStore)
                                        .frame(maxWidth: .infinity)

                                    RSVPOverviewCard(store: guestStore)
                                        .frame(maxWidth: .infinity)
                                }

                                // Vendors & Tasks Row
                                HStack(spacing: Spacing.lg) {
                                    VendorStatusCard(store: vendorStore)
                                        .frame(maxWidth: .infinity)

                                    TaskProgressCard(store: taskStore)
                                        .frame(maxWidth: .infinity)
                                }

                                // Timeline & Activity Row
                                HStack(spacing: Spacing.lg) {
                                    TimelineMilestonesCard(store: timelineStore)
                                        .frame(maxWidth: .infinity)

                                    RecentActivityCard(
                                        budgetStore: budgetStore,
                                        guestStore: guestStore,
                                        taskStore: taskStore
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(Spacing.xxl)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: Spacing.md) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        Button {
                            Task { await loadDashboardData() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(.plain)
                        .accessibleActionButton(label: "Refresh dashboard", hint: "Reload all dashboard data")
                    }
                }
            }
        }
        .sheet(isPresented: $showingTaskModal) {
            TaskModal(
                task: nil,
                onSave: { taskData in
                    await taskStore.createTask(taskData)
                },
                onCancel: {
                    showingTaskModal = false
                }
            )
        }
        .sheet(isPresented: $showingNoteModal) {
            NoteModal(
                note: nil,
                onSave: { noteData in
                    await appStores.notes.createNote(noteData)
                },
                onCancel: {
                    showingNoteModal = false
                }
            )
            .environmentObject(settingsStore)
        }
        .sheet(isPresented: $showingEventModal) {
            TimelineItemModal(
                item: nil,
                onSave: { itemData in
                    await timelineStore.createTimelineItem(itemData)
                },
                onCancel: {
                    showingEventModal = false
                }
            )
            .environmentObject(settingsStore)
        }
        .sheet(isPresented: $showingGuestModal) {
            AddGuestView { newGuest in
                await guestStore.addGuest(newGuest)
            }
        }
        .onAppear {
            if !hasLoaded {
                Task { await loadDashboardData() }
            }
        }
    }

    // MARK: - Computed Properties

    private var weddingDate: Date? {
        guard hasLoaded else {
            logger.debug("Not loaded yet, returning nil for wedding date")
            return nil
        }

        let dateString = settingsStore.settings.global.weddingDate
        guard !dateString.isEmpty else {
            logger.debug("Wedding date string is empty")
            return nil
        }

        logger.debug("Wedding date string from settings: \(dateString)")

        // Try ISO8601 format first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            logger.debug("Parsed wedding date (ISO8601): \(date)")
            return date
        }

        // Try standard date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            logger.debug("Parsed wedding date (yyyy-MM-dd): \(date)")
            return date
        }

        // Try with time component
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: dateString) {
            logger.debug("Parsed wedding date (with time): \(date)")
            return date
        }

        logger.error("Failed to parse wedding date: \(dateString)")
        return nil
    }

    private var daysUntilWedding: Int {
        guard let weddingDate = weddingDate else {
            logger.debug("No wedding date, returning 0")
            return 0
        }

        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let wedding = calendar.startOfDay(for: weddingDate)
        let days = calendar.dateComponents([.day], from: now, to: wedding).day ?? 0

        logger.debug("Days calculation: now=\(now), wedding=\(wedding), days=\(days)")
        return days
    }

    private var budgetColor: Color {
        guard hasLoaded else { return SemanticColors.textSecondary }
        let percentage = budgetStore.percentageSpent
        if percentage >= 100 {
            return SemanticColors.error
        } else if percentage >= 90 {
            return SemanticColors.warning
        } else {
            return SemanticColors.success
        }
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        guard !hasLoaded else {
            logger.info("Already loaded, skipping")
            return
        }

        isLoading = true
        defer { isLoading = false }

        logger.debug("Starting to load all data...")

        // Load data from all stores in parallel
        async let budgetLoad = budgetStore.loadBudgetData()
        async let vendorsLoad = vendorStore.loadVendors()
        async let guestsLoad = guestStore.loadGuestData()
        async let tasksLoad = taskStore.loadTasks()
        async let settingsLoad = settingsStore.loadSettings()
        async let timelineLoad = timelineStore.loadTimelineItems()
        async let documentsLoad = documentStore.loadDocuments()

        // Wait for all to complete
        _ = await (budgetLoad, vendorsLoad, guestsLoad, tasksLoad, settingsLoad, timelineLoad, documentsLoad)

        logger.info("All data loaded successfully")

        // Set hasLoaded AFTER all data is loaded to prevent accessing stores during updates
        hasLoaded = true
    }
}

// MARK: - Preview

#Preview {
    DashboardViewV3()
        .environmentObject(AppStores.shared)
        .frame(width: 1400, height: 900)
}
