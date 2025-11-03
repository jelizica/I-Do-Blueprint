//
//  DashboardViewV2.swift
//  My Wedding Planning App
//
//  Modular puzzle-piece dashboard with sharp edges and interlocking design
//  Created by Claude Code on 10/2/25.
//

import SwiftUI

struct DashboardViewV2: View {
    private let logger = AppLogger.ui
    // Use singleton stores from AppStores to prevent memory explosion
    @EnvironmentObject private var appStores: AppStores

    // Convenience accessors
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var guestStore: GuestStoreV2 { appStores.guest }
    private var taskStore: TaskStoreV2 { appStores.task }
    private var settingsStore: SettingsStoreV2 { appStores.settings }
    private var timelineStore: TimelineStoreV2 { appStores.timeline }
    private var notesStore: NotesStoreV2 { appStores.notes }
    private var documentStore: DocumentStoreV2 { appStores.document }

    @State private var showingTaskModal = false
    @State private var showingNoteModal = false
    @State private var showingEventModal = false
    @State private var showingGuestModal = false
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var summary: DashboardSummary?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    QuickActionsBar(
                        showingTaskModal: $showingTaskModal,
                        showingNoteModal: $showingNoteModal,
                        showingEventModal: $showingEventModal,
                        showingGuestModal: $showingGuestModal
                    )

                    DashboardGridLayout(
                        summary: summary,
                        weddingDate: weddingDate,
                        daysUntilWedding: daysUntilWedding
                    )
                    .padding()
                }
            }
            .background(AppColors.Dashboard.mainBackground)
            .navigationTitle("")
            .toolbar {
                DashboardToolbar(
                    isLoading: isLoading,
                    onRefresh: refresh
                )
            }
            .onAppear {
                // Use onAppear instead of .task to avoid cancellation from view updates
                if !hasLoaded {
                    Task {
                        await loadDashboardData()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTaskModal) {
            Text("Task Modal")
        }
        .sheet(isPresented: $showingNoteModal) {
            Text("Note Modal")
        }
        .sheet(isPresented: $showingEventModal) {
            Text("Event Modal")
        }
        .sheet(isPresented: $showingGuestModal) {
            Text("Guest Modal")
        }
    }

    // MARK: - Computed Properties

    private var weddingDate: Date? {
        guard !settingsStore.settings.global.weddingDate.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: settingsStore.settings.global.weddingDate)
    }

    private var daysUntilWedding: Int {
        guard let weddingDate = weddingDate else { return 0 }
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let wedding = calendar.startOfDay(for: weddingDate)
        return calendar.dateComponents([.day], from: now, to: wedding).day ?? 0
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        // Prevent duplicate loads
        guard !hasLoaded else {
            logger.info("Already loaded, skipping")
            return
        }

        hasLoaded = true
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
        async let notesLoad = notesStore.loadNotes()
        async let documentsLoad = documentStore.loadDocuments()

        // Wait for all to complete
        _ = await (budgetLoad, vendorsLoad, guestsLoad, tasksLoad, settingsLoad, timelineLoad, notesLoad, documentsLoad)

        logger.info("All data loaded, building summary...")

        // Build dashboard summary from store data
        buildDashboardSummary()

        logger.info("Summary built successfully")
    }

    private func refresh() {
        Task {
            await loadDashboardData()
        }
    }

    private func buildDashboardSummary() {
        // Build TaskMetrics
        let tasks = taskStore.tasks
        let completedTasks = tasks.filter { $0.status == .completed }.count
        let inProgressTasks = tasks.filter { $0.status == .inProgress }.count
        let notStartedTasks = tasks.filter { $0.status == .notStarted }.count
        let onHoldTasks = tasks.filter { $0.status == .onHold }.count
        let cancelledTasks = tasks.filter { $0.status == .cancelled }.count
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate, task.status != .completed else { return false }
            return dueDate < Date()
        }.count
        let dueThisWeekTasks = tasks.filter { task in
            guard let dueDate = task.dueDate, task.status != .completed else { return false }
            let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            return dueDate <= weekFromNow && dueDate >= Date()
        }.count
        let highPriorityTasks = tasks.filter { $0.priority == .high }.count
        let urgentTasks = tasks.filter { $0.priority == .urgent }.count
        let completionRate = tasks.isEmpty ? 0.0 : Double(completedTasks) / Double(tasks.count) * 100.0

        let taskMetrics = TaskMetrics(
            total: tasks.count,
            completed: completedTasks,
            inProgress: inProgressTasks,
            notStarted: notStartedTasks,
            onHold: onHoldTasks,
            cancelled: cancelledTasks,
            overdue: overdueTasks,
            dueThisWeek: dueThisWeekTasks,
            highPriority: highPriorityTasks,
            urgent: urgentTasks,
            completionRate: completionRate,
            recentTasks: []
        )

        // Build PaymentMetrics from payment schedules in budget store
        let payments = budgetStore.paymentSchedules
        let totalPayments = payments.count
        let paidPayments = payments.filter { $0.paid }.count
        let unpaidPayments = totalPayments - paidPayments
        let overduePayments = payments.filter { !$0.paid && $0.paymentDate < Date() }.count
        let upcomingPayments = payments.filter { !$0.paid && $0.paymentDate >= Date() }.count
        let totalAmount = payments.reduce(0.0) { $0 + $1.amount }
        let paidAmount = payments.filter { $0.paid }.reduce(0.0) { $0 + $1.amount }
        let unpaidAmount = totalAmount - paidAmount
        let overdueAmount = payments.filter { !$0.paid && $0.paymentDate < Date() }.reduce(0.0) { $0 + $1.amount }

        let paymentMetrics = PaymentMetrics(
            totalPayments: totalPayments,
            paidPayments: paidPayments,
            unpaidPayments: unpaidPayments,
            overduePayments: overduePayments,
            upcomingPayments: upcomingPayments,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            unpaidAmount: unpaidAmount,
            overdueAmount: overdueAmount,
            recentPayments: []
        )

        // Build ReminderMetrics (placeholder - no reminder store yet)
        let reminderMetrics = ReminderMetrics(
            total: 0,
            active: 0,
            completed: 0,
            overdue: 0,
            dueToday: 0,
            dueThisWeek: 0,
            recentReminders: []
        )

        // Build TimelineMetrics - using correct property names
        let timelineItems = timelineStore.timelineItems
        let completedTimelineItems = timelineItems.filter { $0.completed }.count
        let upcomingTimelineItems = timelineItems.filter { !$0.completed && $0.itemDate >= Date() }.count
        let overdueTimelineItems = timelineItems.filter { !$0.completed && $0.itemDate < Date() }.count
        let milestones = timelineItems.filter { $0.itemType == .milestone }.count
        let completedMilestones = timelineItems.filter { $0.itemType == .milestone && $0.completed }.count

        let timelineMetrics = TimelineMetrics(
            totalItems: timelineItems.count,
            completedItems: completedTimelineItems,
            upcomingItems: upcomingTimelineItems,
            overdueItems: overdueTimelineItems,
            milestones: milestones,
            completedMilestones: completedMilestones,
            recentItems: []
        )

        // Build GuestMetrics - using correct RSVPStatus enum values
        let guests = guestStore.guests
        let rsvpYes = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let rsvpNo = guests.filter { $0.rsvpStatus == .declined }.count
        let rsvpPending = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited || $0.rsvpStatus == .maybe }.count

        let guestMetrics = GuestMetrics(
            totalGuests: guests.count,
            rsvpYes: rsvpYes,
            rsvpNo: rsvpNo,
            rsvpPending: rsvpPending,
            attended: 0,
            mealSelections: [:],
            recentRsvps: []
        )

        // Build VendorMetrics - using quotedAmount since there's no status or totalCost
        let vendors = vendorStore.vendors
        let bookedVendors = vendors.filter { $0.isBooked == true }.count
        let availableVendors = vendors.count - bookedVendors
        let totalSpent = vendors.reduce(0.0) { $0 + ($1.quotedAmount ?? 0.0) }

        let vendorMetrics = VendorMetrics(
            totalVendors: vendors.count,
            activeContracts: bookedVendors,
            pendingContracts: availableVendors,
            completedServices: 0,
            totalSpent: totalSpent,
            recentVendors: []
        )

        // Build DocumentMetrics - using DocumentType enum
        let documents = documentStore.documents
        let invoices = documents.filter { $0.documentType == .invoice }.count
        let contracts = documents.filter { $0.documentType == .contract }.count
        let other = documents.filter { $0.documentType == .other || $0.documentType == .receipt || $0.documentType == .photo }.count

        let documentMetrics = DocumentMetrics(
            totalDocuments: documents.count,
            invoices: invoices,
            contracts: contracts,
            other: other,
            recentDocuments: []
        )

        // Build BudgetMetrics - using correct property names
        let totalBudget = budgetStore.actualTotalBudget
        let spent = budgetStore.totalSpent
        let remaining = budgetStore.remainingBudget
        let percentageUsed = budgetStore.percentageSpent

        let budgetMetrics = BudgetMetrics(
            totalBudget: totalBudget,
            spent: spent,
            remaining: remaining,
            percentageUsed: percentageUsed,
            categories: budgetStore.categories.count,
            overBudgetCategories: budgetStore.categories.filter { $0.spentAmount > $0.allocatedAmount }.count,
            recentExpenses: []
        )

        // Build GiftMetrics from budget store gifts
        let giftsReceived = budgetStore.giftsReceived
        let giftsOwed = budgetStore.giftsAndOwed

        let giftMetrics = GiftMetrics(
            totalGifts: giftsReceived.count,
            totalValue: giftsReceived.reduce(0.0) { $0 + $1.amount },
            thankedGifts: 0, // Would need a thanked field
            unthankedGifts: giftsReceived.count,
            recentGifts: []
        )

        // Build NoteMetrics
        let notes = notesStore.notes

        let noteMetrics = NoteMetrics(
            totalNotes: notes.count,
            recentNotes: min(10, notes.count),
            notesByType: [:],
            recentNotesList: []
        )

        // Assemble complete dashboard summary
        summary = DashboardSummary(
            tasks: taskMetrics,
            payments: paymentMetrics,
            reminders: reminderMetrics,
            timeline: timelineMetrics,
            guests: guestMetrics,
            vendors: vendorMetrics,
            documents: documentMetrics,
            budget: budgetMetrics,
            gifts: giftMetrics,
            notes: noteMetrics
        )
    }
}

// MARK: - Preview

#Preview {
    DashboardViewV2()
        .frame(width: 1400, height: 900)
}
