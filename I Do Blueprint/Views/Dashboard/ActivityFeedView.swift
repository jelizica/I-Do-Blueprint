//
//  ActivityFeedView.swift
//  I Do Blueprint
//
//  Activity feed view for collaboration activities
//

import SwiftUI

struct ActivityFeedView: View {
    @StateObject private var store = ActivityFeedStoreV2()
    @State private var showingFilters = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ActivityFeedHeader(
                unreadCount: store.unreadCount,
                hasFilters: hasActiveFilters,
                onMarkAllRead: { Task { await store.markAllAsRead() } },
                onShowFilters: { showingFilters = true }
            )
            
            Divider()
            
            // Content
            Group {
                switch store.loadingState {
                case .idle, .loading:
                    ProgressView("Loading activities...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .loaded:
                    if store.filteredActivities.isEmpty {
                        EmptyActivityView(
                            hasFilters: hasActiveFilters,
                            onClearFilters: { store.clearFilters() }
                        )
                    } else {
                        ActivityListContent(store: store)
                    }
                    
                case .error(let error):
                    ErrorStateView(
                        error: error,
                        onRetry: { Task { await store.retryLoad() } }
                    )
                }
            }
        }
        .navigationTitle("Activity")
        .sheet(isPresented: $showingFilters) {
            ActivityFilterSheet(store: store)
        }
        .task {
            await store.loadActivities(refresh: true)
        }
    }
    
    private var hasActiveFilters: Bool {
        store.selectedActionType != nil ||
        store.selectedResourceType != nil ||
        store.selectedActorId != nil
    }
}

// MARK: - Header

struct ActivityFeedHeader: View {
    let unreadCount: Int
    let hasFilters: Bool
    let onMarkAllRead: () -> Void
    let onShowFilters: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                if unreadCount > 0 {
                    Text("\(unreadCount) unread")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if unreadCount > 0 {
                    Button(action: onMarkAllRead) {
                        Text("Mark All Read")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(action: onShowFilters) {
                    Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(hasFilters ? AppColors.primary : AppColors.textSecondary)
                }
                .accessibilityLabel("Filter activities")
            }
        }
        .padding()
    }
}

// MARK: - List Content

struct ActivityListContent: View {
    @ObservedObject var store: ActivityFeedStoreV2
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.filteredActivities) { activity in
                    CollaborationActivityRow(
                        activity: activity,
                        onMarkRead: {
                            Task { await store.markAsRead(id: activity.id) }
                        }
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                }
                
                // Load more button
                if store.filteredActivities.count >= 50 {
                    Button("Load More") {
                        Task { await store.loadMoreActivities() }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Activity Row

struct CollaborationActivityRow: View {
    let activity: ActivityEvent
    let onMarkRead: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ActivityIcon(actionType: activity.actionType)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.body)
                    .foregroundColor(activity.isRead ? AppColors.textSecondary : AppColors.textPrimary)
                
                Text(activity.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Unread indicator
            if !activity.isRead {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(activity.isRead ? Color.clear : AppColors.cardBackground.opacity(0.3))
        .contentShape(Rectangle())
        .onTapGesture {
            if !activity.isRead {
                onMarkRead()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.description), \(activity.createdAt.formatted(.relative(presentation: .named)))")
        .accessibilityAddTraits(activity.isRead ? [] : [.isButton])
    }
}

// MARK: - Activity Icon

struct ActivityIcon: View {
    let actionType: ActionType
    
    var iconName: String {
        switch actionType {
        case .created: return "plus.circle.fill"
        case .updated: return "pencil.circle.fill"
        case .deleted: return "trash.circle.fill"
        case .viewed: return "eye.circle.fill"
        case .commented: return "bubble.left.circle.fill"
        case .invited: return "person.badge.plus.fill"
        case .joined: return "person.fill.checkmark"
        case .left: return "person.fill.xmark"
        }
    }
    
    var iconColor: Color {
        switch actionType {
        case .created: return AppColors.success
        case .updated: return AppColors.info
        case .deleted: return AppColors.error
        case .viewed: return AppColors.textSecondary
        case .commented: return AppColors.primary
        case .invited, .joined: return AppColors.success
        case .left: return AppColors.warning
        }
    }
    
    var body: some View {
        Image(systemName: iconName)
            .font(.title2)
            .foregroundColor(iconColor)
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)
    }
}

// MARK: - Empty State

struct EmptyActivityView: View {
    let hasFilters: Bool
    let onClearFilters: () -> Void
    
    var body: some View {
        SharedEmptyStateView(
            icon: "clock",
            title: hasFilters ? "No Matching Activities" : "No Activity Yet",
            message: hasFilters ? "Try adjusting your filters to see more activities." : "Activity from your collaborators will appear here.",
            actionTitle: hasFilters ? "Clear Filters" : nil,
            action: hasFilters ? onClearFilters : nil
        )
    }
}

// MARK: - Filter Sheet

struct ActivityFilterSheet: View {
    @ObservedObject var store: ActivityFeedStoreV2
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Filter by Action") {
                    Picker("Action Type", selection: $store.selectedActionType) {
                        Text("All Actions").tag(nil as ActionType?)
                        ForEach([ActionType.created, .updated, .deleted, .commented], id: \.self) { type in
                            Text(type.displayName).tag(type as ActionType?)
                        }
                    }
                }
                
                Section("Filter by Resource") {
                    Picker("Resource Type", selection: $store.selectedResourceType) {
                        Text("All Resources").tag(nil as ResourceType?)
                        ForEach([ResourceType.guest, .budgetCategory, .expense, .vendor, .task], id: \.self) { type in
                            Text(type.displayName.capitalized).tag(type as ResourceType?)
                        }
                    }
                }
                
                Section {
                    Button("Apply Filters") {
                        Task {
                            await store.filterActivities()
                            dismiss()
                        }
                    }
                    
                    Button("Clear All Filters") {
                        store.clearFilters()
                        dismiss()
                    }
                    .foregroundColor(AppColors.error)
                }
            }
            .navigationTitle("Filter Activities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Activity Feed") {
    NavigationStack {
        ActivityFeedView()
    }
}
