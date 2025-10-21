//
//  MoodBoardListView.swift
//  My Wedding Planning App
//
//  List view for mood boards
//

import SwiftUI

struct MoodBoardListView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @State var searchText = ""
    @State var selectedStyleFilter: StyleCategory?
    @State var sortOption: MoodBoardSortOption = .dateCreated
    @State var selectedMoodBoard: MoodBoard?
    @State var viewMode: ViewMode = .grid

    var body: some View {
        VStack(spacing: 0) {
            // Header with inline search
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mood Boards")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("\(filteredMoodBoards.count) mood board\(filteredMoodBoards.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Compact search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.body)
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .frame(width: 200)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    Spacer()

                    // Sort Menu
                    Menu {
                        ForEach(MoodBoardSortOption.allCases, id: \.self) { option in
                            Button(option.displayName) {
                                sortOption = option
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.displayName)
                        }
                        .foregroundColor(.secondary)
                    }

                    // View Mode Toggle
                    HStack(spacing: 4) {
                        Button(action: { viewMode = .grid }) {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(viewMode == .grid ? .blue : .secondary)
                                .padding(6)
                                .background(viewMode == .grid ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Button(action: { viewMode = .list }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(viewMode == .list ? .blue : .secondary)
                                .padding(6)
                                .background(viewMode == .list ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    // Create Button
                    Button(action: {
                        visualPlanningStore.showingMoodBoardCreator = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Mood Board")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                // Filter chips row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        MoodBoardFilterChip(
                            title: "All Styles",
                            isActive: selectedStyleFilter == nil,
                            action: { selectedStyleFilter = nil })

                        ForEach(StyleCategory.allCases.prefix(6), id: \.self) { style in
                            MoodBoardFilterChip(
                                title: style.displayName,
                                isActive: selectedStyleFilter == style,
                                action: { selectedStyleFilter = style })
                        }

                        if selectedStyleFilter != nil {
                            Button(action: { selectedStyleFilter = nil }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Clear")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()

            Divider()

            // Content
            if visualPlanningStore.isLoading {
                // Loading state with skeleton cards
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        ForEach(0 ..< 6, id: \.self) { _ in
                            SkeletonCardLoader()
                        }
                    }
                    .padding()
                }
            } else if filteredMoodBoards.isEmpty {
                UnifiedEmptyStateView(config: .moodBoards(onAdd: {
                    visualPlanningStore.showingMoodBoardCreator = true
                }))
            } else {
                ScrollView {
                    if viewMode == .grid {
                        LazyVGrid(columns: gridColumns, spacing: 20) {
                            ForEach(filteredMoodBoards) { moodBoard in
                                MoodBoardCardView(moodBoard: moodBoard)
                                    .onTapGesture {
                                        selectedMoodBoard = moodBoard
                                    }
                            }
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredMoodBoards) { moodBoard in
                                MoodBoardListRowView(moodBoard: moodBoard)
                                    .onTapGesture {
                                        selectedMoodBoard = moodBoard
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(item: $selectedMoodBoard) { moodBoard in
            MoodBoardDetailView(moodBoard: moodBoard)
                .environmentObject(visualPlanningStore)
        }
    }
}

#Preview {
    MoodBoardListView()
        .environmentObject(VisualPlanningStoreV2())
        .frame(width: 800, height: 600)
}
