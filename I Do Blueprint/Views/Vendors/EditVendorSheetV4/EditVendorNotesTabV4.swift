//
//  EditVendorNotesTabV4.swift
//  I Do Blueprint
//
//  Notes tab for Edit Vendor Modal V4 (Edit Access)
//  Features: Recent notes list, search, note composer with formatting
//

import SwiftUI

struct EditVendorNotesTabV4: View {
    // MARK: - Bindings
    
    @Binding var notes: [VendorNote]
    @Binding var newNoteText: String
    @Binding var searchText: String
    
    // MARK: - Callbacks
    
    let onSaveNote: () -> Void
    
    // MARK: - State
    
    @State private var hoveredNoteId: UUID?
    @State private var editingNoteId: UUID?
    @FocusState private var isNoteFieldFocused: Bool
    
    // MARK: - Computed Properties
    
    private var filteredNotes: [VendorNote] {
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            note.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            headerSection
            
            // Notes List
            notesListSection
            
            // Note Composer
            noteComposerSection
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("Recent Notes")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            Spacer()
            
            // Search Field
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textTertiary)
                
                TextField("Search in notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Typography.bodySmall)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(width: 220)
            .background(SemanticColors.backgroundPrimary.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.pill)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )
        }
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - Notes List Section
    
    private var notesListSection: some View {
        ScrollView {
            if filteredNotes.isEmpty {
                emptyNotesView
            } else {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(filteredNotes) { note in
                        noteCard(note)
                    }
                }
            }
        }
        .frame(maxHeight: 350)
    }
    
    // MARK: - Note Card
    
    private func noteCard(_ note: VendorNote) -> some View {
        let isHovered = hoveredNoteId == note.id
        
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack {
                // Author Badge
                Text(note.authorType.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(note.authorType.color)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(note.authorType.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                
                // Timestamp
                Text(formatNoteDate(note.createdAt))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
                
                Spacer()
                
                // Action Buttons (shown on hover)
                if isHovered {
                    HStack(spacing: Spacing.xs) {
                        noteActionButton(icon: "pencil", action: {
                            editingNoteId = note.id
                        })
                        
                        noteActionButton(icon: "trash", isDestructive: true, action: {
                            deleteNote(note)
                        })
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            
            // Content
            Text(note.content)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .macOSShadow(isHovered ? .elevated : .subtle)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredNoteId = hovering ? note.id : nil
            }
        }
    }
    
    private func noteActionButton(icon: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isDestructive ? SemanticColors.statusError : SemanticColors.textSecondary)
                .frame(width: 28, height: 28)
                .background(
                    isDestructive
                        ? SemanticColors.statusError.opacity(Opacity.verySubtle)
                        : SemanticColors.backgroundSecondary
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Note Composer Section
    
    private var noteComposerSection: some View {
        VStack(spacing: 0) {
            // Text Area
            ZStack(alignment: .topLeading) {
                if newNoteText.isEmpty {
                    Text("Type a note about this vendor...")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textTertiary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.md)
                }
                
                TextEditor(text: $newNoteText)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.sm)
                    .focused($isNoteFieldFocused)
            }
            .frame(height: 100)
            
            // Toolbar
            HStack {
                // Formatting Buttons
                HStack(spacing: Spacing.xs) {
                    formattingButton(icon: "paperclip")
                    formattingButton(icon: "bold")
                    formattingButton(icon: "list.bullet")
                }
                
                Spacer()
                
                // Keyboard Shortcut Hint
                Text("Press ⌘ + Enter to save")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(SemanticColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                // Save Button
                Button {
                    onSaveNote()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text("Save Note")
                            .font(Typography.bodySmall)
                            .fontWeight(.medium)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(SemanticColors.primaryAction)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .macOSShadow(.subtle)
                }
                .buttonStyle(.plain)
                .disabled(newNoteText.isEmpty)
                .opacity(newNoteText.isEmpty ? 0.6 : 1.0)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    isNoteFieldFocused
                        ? SemanticColors.primaryAction.opacity(0.5)
                        : SemanticColors.borderLight,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isNoteFieldFocused)
        .onSubmit {
            if !newNoteText.isEmpty {
                onSaveNote()
            }
        }
    }
    
    private func formattingButton(icon: String) -> some View {
        Button {
            // Formatting action placeholder
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textTertiary)
                .frame(width: 28, height: 28)
                .background(SemanticColors.backgroundPrimary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    
    private var emptyNotesView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "note.text")
                .font(.system(size: 36))
                .foregroundColor(SemanticColors.textTertiary)
            
            VStack(spacing: Spacing.xs) {
                Text(searchText.isEmpty ? "No Notes Yet" : "No Matching Notes")
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(searchText.isEmpty
                     ? "Add your first note about this vendor below."
                     : "Try adjusting your search terms.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
    
    // MARK: - Helper Methods
    
    private func formatNoteDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func deleteNote(_ note: VendorNote) {
        withAnimation(.easeInOut(duration: 0.2)) {
            notes.removeAll { $0.id == note.id }
        }
    }
    
    // MARK: - Helper Views
    
    private var glassCardBackground: some View {
        SemanticColors.backgroundPrimary.opacity(0.6)
    }
}

// MARK: - Preview

#Preview("Notes Tab") {
    EditVendorNotesTabV4(
        notes: .constant([
            VendorNote(
                id: UUID(),
                content: "Discussed the bridal party timeline. Furi mentioned she needs early access to the venue (around 8 AM) to set up the lighting for makeup stations. Need to confirm with venue coordinator.",
                authorType: .partner1,
                createdAt: Date()
            ),
            VendorNote(
                id: UUID(),
                content: "Deposit payment of $918.75 was marked as paid via Bank Transfer.",
                authorType: .system,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            VendorNote(
                id: UUID(),
                content: "We might need to add 2 more bridesmaids to the package later. Waiting for confirmation from Sarah and Jessica.",
                authorType: .partner2,
                createdAt: Date().addingTimeInterval(-86400 * 30)
            )
        ]),
        newNoteText: .constant(""),
        searchText: .constant(""),
        onSaveNote: {}
    )
    .padding()
    .frame(width: 850, height: 600)
}

#Preview("Notes Tab - Empty") {
    EditVendorNotesTabV4(
        notes: .constant([]),
        newNoteText: .constant(""),
        searchText: .constant(""),
        onSaveNote: {}
    )
    .padding()
    .frame(width: 850, height: 500)
}
