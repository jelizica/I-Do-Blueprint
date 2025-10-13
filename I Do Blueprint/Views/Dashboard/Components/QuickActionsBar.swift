//
//  QuickActionsBar.swift
//  My Wedding Planning App
//
//  Extracted component for quick action buttons
//  Created by Claude Code on 1/9/25.
//

import SwiftUI

struct QuickActionsBar: View {
    @Binding var showingTaskModal: Bool
    @Binding var showingNoteModal: Bool
    @Binding var showingEventModal: Bool
    @Binding var showingGuestModal: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            QuickActionButtonV2(
                icon: "plus.circle.fill",
                title: "Task",
                backgroundColor: DashboardColors.taskAction) {
                showingTaskModal = true
            }
            .accessibilityLabel("Add Task")
            .accessibilityHint("Creates a new task")

            QuickActionButtonV2(
                icon: "note.text",
                title: "Note",
                backgroundColor: DashboardColors.noteAction) {
                showingNoteModal = true
            }
            .accessibilityLabel("Add Note")
            .accessibilityHint("Creates a new note")

            QuickActionButtonV2(
                icon: "calendar",
                title: "Event",
                backgroundColor: DashboardColors.eventAction) {
                showingEventModal = true
            }
            .accessibilityLabel("Add Event")
            .accessibilityHint("Creates a new calendar event")

            QuickActionButtonV2(
                icon: "person.crop.circle.badge.plus",
                title: "Guest",
                backgroundColor: DashboardColors.guestAction) {
                showingGuestModal = true
            }
            .accessibilityLabel("Add Guest")
            .accessibilityHint("Adds a new guest to the list")

            Spacer()
        }
        .padding()
        .background(DashboardColors.quickActionsBackground)
    }
}

// MARK: - Preview

#Preview {
    QuickActionsBar(
        showingTaskModal: .constant(false),
        showingNoteModal: .constant(false),
        showingEventModal: .constant(false),
        showingGuestModal: .constant(false)
    )
    .frame(width: 600)
}
