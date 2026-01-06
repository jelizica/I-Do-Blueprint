//
//  VendorDetailNotesTabV2.swift
//  I Do Blueprint
//
//  Enhanced notes tab with searchable note cards and add functionality
//

import SwiftUI

struct VendorDetailNotesTabV2: View {
    let vendor: Vendor
    @ObservedObject var vendorStore: VendorStoreV2

    @State private var searchText = ""
    @State private var isAddingNote = false
    @State private var newNoteText = ""
    @State private var isEditing = false
    @State private var editedNotes = ""

    // For demo purposes, we'll split the notes into "cards"
    // In a real app, this would be a separate VendorNote model
    private var noteCards: [VendorNoteCard] {
        guard let notes = vendor.notes, !notes.isEmpty else { return [] }

        // Split notes by double newlines to create separate cards
        let segments = notes.components(separatedBy: "\n\n")
        return segments.enumerated().map { index, content in
            VendorNoteCard(
                id: index,
                title: "Note \(index + 1)",
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                author: "You",
                date: vendor.updatedAt ?? vendor.createdAt
            )
        }.filter { !$0.content.isEmpty }
    }

    private var filteredNotes: [VendorNoteCard] {
        guard !searchText.isEmpty else { return noteCards }
        return noteCards.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Search and Add Bar
            searchAndAddBar

            // Notes Content
            if noteCards.isEmpty {
                emptyNotesView
            } else if filteredNotes.isEmpty {
                noSearchResultsView
            } else {
                notesListView
            }
        }
    }

    // MARK: - Components

    private var searchAndAddBar: some View {
        HStack(spacing: Spacing.md) {
            // Search Field
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textSecondary)

                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Typography.bodyRegular)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.sm)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)

            // Add Note Button
            Button(action: { isAddingNote = true }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Note")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.primaryAction)
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
    }

    private var notesListView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeaderV2(
                    title: "Notes (\(filteredNotes.count))",
                    icon: "note.text.fill",
                    color: SemanticColors.primaryAction
                )

                Spacer()

                if !isEditing {
                    Button(action: { startEditing() }) {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                            Text("Edit All")
                                .font(Typography.caption)
                        }
                        .foregroundColor(SemanticColors.primaryAction)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isEditing {
                // Edit mode - show text editor
                editingView
            } else {
                // View mode - show note cards
                LazyVStack(spacing: Spacing.md) {
                    ForEach(filteredNotes) { note in
                        NoteCardV2(note: note)
                    }
                }
            }
        }
    }

    private var editingView: some View {
        VStack(spacing: Spacing.md) {
            TextEditor(text: $editedNotes)
                .font(Typography.bodyRegular)
                .padding(Spacing.sm)
                .frame(minHeight: 200)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderLight, lineWidth: 1)
                )

            HStack {
                Button(action: { cancelEditing() }) {
                    Text("Cancel")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(SemanticColors.backgroundSecondary)
                        .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: { saveEditing() }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Save")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(SemanticColors.success)
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }

    private var emptyNotesView: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(SemanticColors.primaryAction.opacity(Opacity.subtle))
                    .frame(width: 80, height: 80)

                Image(systemName: "note.text")
                    .font(.system(size: 36))
                    .foregroundColor(SemanticColors.primaryAction)
            }

            VStack(spacing: Spacing.xs) {
                Text("No Notes Yet")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Add notes to keep track of important details about this vendor.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { isAddingNote = true }) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Your First Note")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(SemanticColors.primaryAction)
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .sheet(isPresented: $isAddingNote) {
            AddNoteSheetV2(
                vendorName: vendor.vendorName,
                onSave: { noteText in
                    addNote(noteText)
                }
            )
        }
    }

    private var noSearchResultsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(SemanticColors.textSecondary.opacity(Opacity.medium))

            VStack(spacing: Spacing.xs) {
                Text("No Results")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("No notes match \"\(searchText)\"")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Button(action: { searchText = "" }) {
                Text("Clear Search")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.primaryAction)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxl)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Actions

    private func addNote(_ noteText: String) {
        var updatedVendor = vendor
        if let existingNotes = vendor.notes, !existingNotes.isEmpty {
            updatedVendor.notes = existingNotes + "\n\n" + noteText
        } else {
            updatedVendor.notes = noteText
        }
        Task {
            await vendorStore.updateVendor(updatedVendor)
        }
        isAddingNote = false
        newNoteText = ""
    }

    private func startEditing() {
        editedNotes = vendor.notes ?? ""
        isEditing = true
    }

    private func cancelEditing() {
        isEditing = false
        editedNotes = ""
    }

    private func saveEditing() {
        var updatedVendor = vendor
        updatedVendor.notes = editedNotes.isEmpty ? nil : editedNotes
        Task {
            await vendorStore.updateVendor(updatedVendor)
        }
        isEditing = false
    }
}

// MARK: - Supporting Types

struct VendorNoteCard: Identifiable {
    let id: Int
    let title: String
    let content: String
    let author: String
    let date: Date
}

// MARK: - Supporting Views

struct NoteCardV2: View {
    let note: VendorNoteCard

    @State private var isExpanded = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(SemanticColors.primaryAction.opacity(Opacity.subtle))
                            .frame(width: 32, height: 32)

                        Text(note.author.prefix(1).uppercased())
                            .font(Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.primaryAction)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(note.author)
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.textPrimary)

                        Text(note.date.formatted(date: .abbreviated, time: .shortened))
                            .font(Typography.caption2)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }

                Spacer()

                if note.content.count > 150 {
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Content
            Text(note.content)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(isExpanded ? nil : 3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(isHovering ? SemanticColors.primaryAction.opacity(Opacity.semiLight) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct AddNoteSheetV2: View {
    let vendorName: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Add Note")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("for \(vendorName)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(SemanticColors.backgroundSecondary)
                        .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.xl)

            Divider()

            // Content
            VStack(spacing: Spacing.md) {
                TextEditor(text: $noteText)
                    .font(Typography.bodyRegular)
                    .padding(Spacing.sm)
                    .frame(minHeight: 200)
                    .background(SemanticColors.backgroundSecondary)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.borderLight, lineWidth: 1)
                    )
                    .focused($isFocused)

                Text("\(noteText.count) characters")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(Spacing.xl)

            Divider()

            // Actions
            HStack {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(SemanticColors.backgroundSecondary)
                        .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    onSave(noteText)
                    dismiss()
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Save Note")
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(noteText.isEmpty ? SemanticColors.textSecondary : SemanticColors.primaryAction)
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(noteText.isEmpty)
            }
            .padding(Spacing.xl)
        }
        .frame(width: 500, height: 400)
        .background(SemanticColors.backgroundPrimary)
        .onAppear {
            isFocused = true
        }
    }
}
