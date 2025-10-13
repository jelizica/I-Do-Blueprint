//
//  DashboardView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab: DashboardTab = .overview
    @State private var showingTaskModal = false
    @State private var showingNoteModal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Header
                    heroHeader

                    // Quick Actions
                    quickActions

                    // Priority & Alerts Section
                    if viewModel.hasPriorityAlerts {
                        priorityAlertsSection
                    }

                    // Core Planning Section
                    corePlanningSection

                    // Financial Management Section
                    financialSection

                    // Organization & Settings Section
                    organizationSection
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
            .navigationTitle("Wedding Dashboard")
            .accessibilityAddTraits(.isHeader)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { Task { await viewModel.refresh() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $showingTaskModal) {
            Text("Task Modal")
        }
        .sheet(isPresented: $showingNoteModal) {
            Text("Note Modal")
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome Back!")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing))
                .accessibilityAddTraits(.isHeader)

            if let weddingDate = viewModel.weddingDate {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)

                    Text("\(viewModel.daysUntilWedding) days until your wedding")
                        .font(.title3)
                        .fontWeight(.medium)

                    Spacer()

                    Text(weddingDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            .linearGradient(
                                colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing)))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Wedding countdown: \(viewModel.daysUntilWedding) days until your wedding on \(weddingDate.formatted(date: .long, time: .omitted))")
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                DashboardQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Task",
                    color: .blue) {
                    showingTaskModal = true
                }

                DashboardQuickActionButton(
                    icon: "note.text.badge.plus",
                    title: "New Note",
                    color: .green) {
                    showingNoteModal = true
                }

                DashboardQuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add Event",
                    color: .orange) {
                    // TODO: Show event modal
                }

                DashboardQuickActionButton(
                    icon: "person.crop.circle.badge.plus",
                    title: "Add Guest",
                    color: .purple) {
                    // TODO: Show guest modal
                }
            }
        }
    }

    // MARK: - Priority & Alerts Section

    private var priorityAlertsSection: some View {
        DashboardSection(
            title: "Priority & Alerts",
            description: "Urgent items that need immediate attention",
            icon: "exclamationmark.triangle.fill",
            iconColor: .red,
            priority: .high) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                if let taskMetrics = viewModel.summary?.tasks {
                    TasksSummaryCard(metrics: taskMetrics)
                }

                if let paymentMetrics = viewModel.summary?.payments {
                    PaymentsSummaryCard(metrics: paymentMetrics)
                }

                if let reminderMetrics = viewModel.summary?.reminders {
                    RemindersSummaryCard(metrics: reminderMetrics)
                }

                if let timelineMetrics = viewModel.summary?.timeline {
                    TimelineSummaryCard(metrics: timelineMetrics)
                }
            }
        }
    }

    // MARK: - Core Planning Section

    private var corePlanningSection: some View {
        DashboardSection(
            title: "Core Planning",
            description: "Manage guests, vendors, and planning tasks",
            icon: "list.clipboard.fill",
            iconColor: .blue,
            priority: .medium) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                if let guestMetrics = viewModel.summary?.guests {
                    GuestsSummaryCard(metrics: guestMetrics)
                }

                if let vendorMetrics = viewModel.summary?.vendors {
                    VendorsSummaryCard(metrics: vendorMetrics)
                }

                if let documentMetrics = viewModel.summary?.documents {
                    DocumentsSummaryCard(metrics: documentMetrics)
                }
            }
        }
    }

    // MARK: - Financial Section

    private var financialSection: some View {
        DashboardSection(
            title: "Financial Management",
            description: "Track budget, expenses, and gift registry",
            icon: "dollarsign.circle.fill",
            iconColor: .green,
            priority: .medium) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                if let budgetMetrics = viewModel.summary?.budget {
                    DashboardBudgetSummaryCard(metrics: budgetMetrics)
                }

                if let giftMetrics = viewModel.summary?.gifts {
                    GiftsSummaryCard(metrics: giftMetrics)
                }
            }
        }
    }

    // MARK: - Organization Section

    private var organizationSection: some View {
        DashboardSection(
            title: "Organization & Notes",
            description: "Keep track of important notes and links",
            icon: "folder.fill",
            iconColor: .orange,
            priority: .normal) {
            if let noteMetrics = viewModel.summary?.notes {
                NotesSummaryCard(metrics: noteMetrics)
            }
        }
    }
}

// MARK: - Dashboard Tab

enum DashboardTab: String, CaseIterable {
    case overview = "Overview"
    case tasks = "Tasks"
    case timeline = "Timeline"
    case budget = "Budget"

    var icon: String {
        switch self {
        case .overview: "house.fill"
        case .tasks: "checklist"
        case .timeline: "calendar"
        case .budget: "dollarsign.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .frame(width: 1200, height: 800)
}
