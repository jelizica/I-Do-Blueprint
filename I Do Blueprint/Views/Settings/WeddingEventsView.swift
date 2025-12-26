//
//  WeddingEventsView.swift
//  I Do Blueprint
//
//  Wedding events management view for Settings
//

import SwiftUI

struct WeddingEventsView: View {
    @Environment(\.appStores) private var appStores
    @State private var events: [WeddingEvent] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingAddEvent = false
    @State private var editingEvent: WeddingEvent?
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: WeddingEvent?
    
    private var budgetStore: BudgetStoreV2 {
        appStores.budget
    }
    
    private let logger = AppLogger.ui
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wedding Events")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Manage your wedding events and link them to budget items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingAddEvent = true }) {
                    Label("Add Event", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Content
            if isLoading {
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading events...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                WeddingEventsErrorStateView(
                    title: "Failed to Load Events",
                    message: error.localizedDescription,
                    retryAction: {
                        Task { await loadEvents() }
                    }
                )
            } else if events.isEmpty {
                WeddingEventsEmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "No Events Yet",
                    message: "Add your wedding events to organize your budget and planning",
                    actionTitle: "Add First Event",
                    action: { showingAddEvent = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(events.sorted(by: { ($0.eventOrder ?? 0) < ($1.eventOrder ?? 0) }), id: \.id) { event in
                            EventRowView(
                                event: event,
                                onEdit: {
                                    editingEvent = event
                                },
                                onDelete: {
                                    eventToDelete = event
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadEvents()
        }
        .sheet(isPresented: $showingAddEvent) {
            EventFormView(
                mode: .create,
                onSave: { newEvent in
                    Task {
                        await createEvent(newEvent)
                    }
                },
                onCancel: {
                    showingAddEvent = false
                }
            )
        }
        .sheet(item: $editingEvent) { event in
            EventFormView(
                mode: .edit(event),
                onSave: { updatedEvent in
                    Task {
                        await updateEvent(updatedEvent)
                    }
                },
                onCancel: {
                    editingEvent = nil
                }
            )
        }
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                eventToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let event = eventToDelete {
                    Task {
                        await deleteEvent(event)
                    }
                }
            }
        } message: {
            if let event = eventToDelete {
                Text("Are you sure you want to delete '\(event.eventName)'? This will unlink it from any budget items.")
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadEvents() async {
        isLoading = true
        error = nil
        
        do {
            events = try await budgetStore.fetchWeddingEvents()
            logger.info("Loaded \(events.count) wedding events")
        } catch {
            self.error = error
            logger.error("Failed to load wedding events", error: error)
        }
        
        isLoading = false
    }
    
    private func createEvent(_ event: WeddingEvent) async {
        do {
            let created = try await budgetStore.createWeddingEvent(event)
            events.append(created)
            events.sort { ($0.eventOrder ?? 0) < ($1.eventOrder ?? 0) }
            showingAddEvent = false
            logger.info("Created wedding event: \(created.eventName)")
        } catch {
            self.error = error
            logger.error("Failed to create wedding event", error: error)
        }
    }
    
    private func updateEvent(_ event: WeddingEvent) async {
        do {
            let updated = try await budgetStore.updateWeddingEvent(event)
            if let index = events.firstIndex(where: { $0.id == updated.id }) {
                events[index] = updated
            }
            editingEvent = nil
            logger.info("Updated wedding event: \(updated.eventName)")
        } catch {
            self.error = error
            logger.error("Failed to update wedding event", error: error)
        }
    }
    
    private func deleteEvent(_ event: WeddingEvent) async {
        do {
            try await budgetStore.deleteWeddingEvent(id: event.id)
            events.removeAll { $0.id == event.id }
            eventToDelete = nil
            logger.info("Deleted wedding event: \(event.eventName)")
        } catch {
            self.error = error
            eventToDelete = nil
            logger.error("Failed to delete wedding event", error: error)
        }
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: WeddingEvent
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Event icon
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: eventIcon)
                    .font(.system(size: 20))
                    .foregroundColor(eventColor)
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.eventName)
                        .font(.headline)
                    
                    if event.isMainEvent == true {
                        Text("MAIN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: Spacing.sm) {
                    Label(formatDate(event.eventDate), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let startTime = event.startTime {
                        Label(formatTime(startTime), systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let venueName = event.venueName {
                    Label(venueName, systemImage: "mappin.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: Spacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var eventColor: Color {
        switch event.eventType.lowercased() {
        case "ceremony": return .purple
        case "reception": return .blue
        case "rehearsal": return .orange
        case "brunch": return .yellow
        case "party": return .pink
        default: return .gray
        }
    }
    
    private var eventIcon: String {
        switch event.eventType.lowercased() {
        case "ceremony": return "heart.fill"
        case "reception": return "party.popper.fill"
        case "rehearsal": return "music.note"
        case "brunch": return "cup.and.saucer.fill"
        case "party": return "sparkles"
        default: return "calendar"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Empty State View (Local to WeddingEventsView)

private struct WeddingEventsEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Button(action: action) {
                Label(actionTitle, systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Error State View (Local to WeddingEventsView)

private struct WeddingEventsErrorStateView: View {
    let title: String
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    WeddingEventsView()
        .frame(width: 800, height: 600)
}
