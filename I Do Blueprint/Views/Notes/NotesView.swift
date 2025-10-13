//
//  NotesView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct NotesView: View {
    @StateObject private var viewModel = NotesStoreV2()
    @State private var showingNoteModal = false
    @State private var selectedNote: Note?
    @State private var showGrouped = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar with inline controls
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search notes...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor)))

                    Spacer()

                    // View mode toggle
                    Picker("View", selection: $showGrouped) {
                        Label("Grouped", systemImage: "square.grid.2x2").tag(true)
                        Label("List", systemImage: "list.bullet").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)

                    // Type filter
                    Menu {
                        Button("All Types") {
                            viewModel.selectedType = nil
                            viewModel.applyFilters()
                        }

                        Divider()

                        ForEach(NoteRelatedType.allCases, id: \.self) { type in
                            Button(type.displayName) {
                                viewModel.selectedType = type
                                viewModel.applyFilters()
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 20))
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))

                Divider()

                // Content
                Group {
                    if viewModel.isLoading, viewModel.notes.isEmpty {
                        loadingView
                    } else if viewModel.filteredNotes.isEmpty {
                        emptyStateView
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { Task { await viewModel.refresh() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }

                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        selectedNote = nil
                        showingNoteModal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNoteModal) {
                NoteModal(
                    note: selectedNote,
                    onSave: { data in
                        if let note = selectedNote {
                            await viewModel.updateNote(note.id, data: data)
                        } else {
                            await viewModel.createNote(data)
                        }
                        selectedNote = nil
                    },
                    onCancel: {
                        selectedNote = nil
                    })
            }
            .onChange(of: viewModel.searchText) { _, _ in
                Task {
                    await viewModel.searchNotes()
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: Spacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    NoteCardSkeleton()
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create your first note to start organizing your wedding planning thoughts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: {
                selectedNote = nil
                showingNoteModal = true
            }) {
                Label("Create Note", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        HStack(spacing: 12) {
            // View mode toggle
            Picker("View", selection: $showGrouped) {
                Label("Grouped", systemImage: "square.grid.2x2").tag(true)
                Label("List", systemImage: "list.bullet").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            // Type filter
            Menu {
                Button("All Types") {
                    viewModel.selectedType = nil
                    viewModel.applyFilters()
                }

                Divider()

                ForEach(NoteRelatedType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        viewModel.selectedType = type
                        viewModel.applyFilters()
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }

            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)

            Button(action: {
                selectedNote = nil
                showingNoteModal = true
            }) {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if showGrouped {
                    groupedNotesView
                } else {
                    listNotesView
                }
            }
            .padding()
        }
    }

    // MARK: - Grouped Notes View

    private var groupedNotesView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Ungrouped notes first
            let ungrouped = viewModel.ungroupedNotes()
            if !ungrouped.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("General Notes")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 300), spacing: 16)
                    ], spacing: 16) {
                        ForEach(ungrouped) { note in
                            NoteCard(
                                note: note,
                                onTap: {
                                    selectedNote = note
                                    showingNoteModal = true
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteNote(note.id)
                                    }
                                })
                        }
                    }
                }
            }

            // Grouped notes by type
            ForEach(
                Array(viewModel.groupedNotesByType().keys.sorted(by: { $0.rawValue < $1.rawValue })),
                id: \.self) { type in
                if let notesForType = viewModel.groupedNotesByType()[type] {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: type.iconName)
                                .foregroundColor(typeColor(type))
                            Text(type.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("(\(notesForType.count))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 300), spacing: 16)
                        ], spacing: 16) {
                            ForEach(notesForType) { note in
                                NoteCard(
                                    note: note,
                                    onTap: {
                                        selectedNote = note
                                        showingNoteModal = true
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteNote(note.id)
                                        }
                                    })
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - List Notes View

    private var listNotesView: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.filteredNotes) { note in
                NoteCard(
                    note: note,
                    onTap: {
                        selectedNote = note
                        showingNoteModal = true
                    },
                    onDelete: {
                        Task {
                            await viewModel.deleteNote(note.id)
                        }
                    })
            }
        }
    }

    // MARK: - Helpers

    private func typeColor(_ type: NoteRelatedType) -> Color {
        switch type {
        case .vendor: .purple
        case .guest: .blue
        case .task: .orange
        case .milestone: .yellow
        case .budget: .green
        case .visualElement: .pink
        case .payment: .teal
        case .document: .indigo
        }
    }
}

// MARK: - Preview

#Preview {
    NotesView()
        .frame(width: 1200, height: 800)
}
