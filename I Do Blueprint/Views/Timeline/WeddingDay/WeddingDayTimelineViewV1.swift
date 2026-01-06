//
//  WeddingDayTimelineViewV1.swift
//  I Do Blueprint
//
//  Wedding Day Timeline - Main Container View
//  Provides view mode switching between List, Wall, and Gantt views
//

import SwiftUI

struct WeddingDayTimelineViewV1: View {
    @EnvironmentObject private var store: TimelineStoreV2

    // MARK: - State
    @State private var selectedViewMode: WeddingDayViewMode = .list
    @State private var showingAddEvent = false
    @State private var isRefreshing = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with view mode picker
            headerView

            Divider()

            // Content based on selected view mode
            contentView
        }
        .background(AppColors.background)
        .navigationTitle("Wedding Day Timeline")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarItems
            }
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showingAddEvent) {
            addEventSheet
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: Spacing.lg) {
            // View mode picker
            viewModePicker

            Spacer()

            // Stats summary
            statsSummary
        }
        .padding()
        .background(AppColors.cardBackground)
    }

    private var viewModePicker: some View {
        HStack(spacing: 2) {
            ForEach(WeddingDayViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedViewMode = mode
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))

                        Text(mode.displayName)
                            .font(Typography.subheading)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        selectedViewMode == mode
                            ? TimelineColors.primary
                            : Color.clear
                    )
                    .foregroundColor(
                        selectedViewMode == mode
                            ? .white
                            : AppColors.textSecondary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var statsSummary: some View {
        HStack(spacing: Spacing.lg) {
            statItem(
                value: "\(store.weddingDayEvents.count)",
                label: "Events",
                icon: "calendar"
            )

            statItem(
                value: "\(confirmedCount)",
                label: "Confirmed",
                icon: "checkmark.seal.fill",
                color: TimelineColors.statusReady
            )

            statItem(
                value: "\(pendingCount)",
                label: "Pending",
                icon: "clock",
                color: TimelineColors.statusPending
            )
        }
    }

    private func statItem(value: String, label: String, icon: String, color: Color = AppColors.textSecondary) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(Typography.heading)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)

                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch store.weddingDayEventsLoadingState {
        case .idle, .loading:
            loadingView

        case .loaded:
            if store.weddingDayEvents.isEmpty {
                emptyStateView
            } else {
                selectedContentView
            }

        case .error(let error):
            errorView(error: error)
        }
    }

    @ViewBuilder
    private var selectedContentView: some View {
        switch selectedViewMode {
        case .list:
            TimelineListViewV1()
                .transition(.opacity)

        case .wall:
            TimelineWallViewV1()
                .transition(.opacity)

        case .gantt:
            TimelineGanttViewV1()
                .transition(.opacity)
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading timeline...")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            // Illustration
            ZStack {
                Circle()
                    .fill(TimelineColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(TimelineColors.primary)
            }

            VStack(spacing: Spacing.sm) {
                Text("No Events Yet")
                    .font(Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)

                Text("Start planning your wedding day by adding your first event.")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                showingAddEvent = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Event")
                }
                .font(Typography.heading)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(TimelineColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private func errorView(error: Error) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(TimelineColors.statusPending)

            VStack(spacing: Spacing.sm) {
                Text("Something went wrong")
                    .font(Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)

                Text(error.localizedDescription)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                Task {
                    await loadData()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(Typography.heading)
                .fontWeight(.medium)
                .foregroundColor(TimelineColors.primary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar Items

    @ViewBuilder
    private var toolbarItems: some View {
        Button {
            Task {
                isRefreshing = true
                await loadData(force: true)
                isRefreshing = false
            }
        } label: {
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .help("Refresh timeline")

        Button {
            showingAddEvent = true
        } label: {
            Image(systemName: "plus")
        }
        .help("Add new event")
    }

    // MARK: - Add Event Sheet

    private var addEventSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text("Add Event")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Text("Event creation form would go here.")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Button("Cancel") {
                    showingAddEvent = false
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddEvent = false
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // MARK: - Computed Properties

    private var confirmedCount: Int {
        store.weddingDayEvents.filter {
            $0.status == .confirmed || $0.status == .ready || $0.status == .completed
        }.count
    }

    private var pendingCount: Int {
        store.weddingDayEvents.filter {
            $0.status == .pending || $0.status == .onTrack
        }.count
    }

    // MARK: - Data Loading

    private func loadData(force: Bool = false) async {
        await store.loadWeddingDayEvents(force: force)
    }
}

// MARK: - Preview

#Preview {
    WeddingDayTimelineViewV1()
        .environmentObject(TimelineStoreV2())
        .frame(width: 1200, height: 800)
}
