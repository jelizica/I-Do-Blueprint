//
//  MoodBoardListView.swift
//  My Wedding Planning App
//
//  List view for mood boards
//

import SwiftUI

enum ViewMode {
    case grid
    case list
}

struct MoodBoardListView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @State private var searchText = ""
    @State private var selectedStyleFilter: StyleCategory?
    @State private var sortOption: MoodBoardSortOption = .dateCreated
    @State private var selectedMoodBoard: MoodBoard?
    @State private var viewMode: ViewMode = .grid

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
                EmptyMoodBoardView()
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

    private var filteredMoodBoards: [MoodBoard] {
        var boards = visualPlanningStore.moodBoards

        // Apply style filter
        if let styleFilter = selectedStyleFilter {
            boards = boards.filter { $0.styleCategory == styleFilter }
        }

        // Apply search filter
        if !searchText.isEmpty {
            boards = boards.filter { board in
                board.boardName.localizedCaseInsensitiveContains(searchText) ||
                    board.boardDescription?.localizedCaseInsensitiveContains(searchText) == true ||
                    board.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Apply sorting
        switch sortOption {
        case .dateCreated:
            return boards.sorted { $0.createdAt > $1.createdAt }
        case .dateModified:
            return boards.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return boards.sorted { $0.boardName < $1.boardName }
        case .style:
            return boards.sorted { $0.styleCategory.displayName < $1.styleCategory.displayName }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)
        ]
    }
}

enum MoodBoardSortOption: CaseIterable {
    case dateCreated
    case dateModified
    case name
    case style

    var displayName: String {
        switch self {
        case .dateCreated: "Date Created"
        case .dateModified: "Date Modified"
        case .name: "Name"
        case .style: "Style"
        }
    }
}

// MARK: - List Row View

struct MoodBoardListRowView: View {
    let moodBoard: MoodBoard
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail preview
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                moodBoard.backgroundColor.opacity(0.4),
                                moodBoard.backgroundColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .frame(width: 120, height: 80)

                if !moodBoard.elements.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(moodBoard.elements.prefix(2)) { element in
                            MoodBoardElementPreview(element: element)
                                .frame(width: 56, height: 76)
                        }
                    }
                    .padding(2)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(moodBoard.boardName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: moodBoard.styleCategory.iconName)
                            .foregroundColor(.blue)
                        Text(moodBoard.styleCategory.displayName)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }

                if let description = moodBoard.boardDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Label("\(moodBoard.elements.count) elements", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(moodBoard.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Quick actions on hover
            if isHovering {
                HStack(spacing: 8) {
                    MoodBoardQuickActionButton(icon: "pencil", color: .blue)
                    MoodBoardQuickActionButton(icon: "doc.on.doc", color: .green)
                    MoodBoardQuickActionButton(icon: "trash", color: .red)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.12 : 0.06),
                    radius: isHovering ? 8 : 4,
                    x: 0,
                    y: isHovering ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1))
        .scaleEffect(isHovering ? 1.005 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

struct MoodBoardCardView: View {
    let moodBoard: MoodBoard
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview/Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                moodBoard.backgroundColor.opacity(0.4),
                                moodBoard.backgroundColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(moodBoard.backgroundColor.opacity(0.3), lineWidth: 1))

                if !moodBoard.elements.isEmpty {
                    // 2x2 grid preview of elements
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(moodBoard.elements.prefix(4)) { element in
                            MoodBoardElementPreview(element: element)
                        }
                    }
                    .padding(16)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Empty Board")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Quick actions overlay on hover
                if isHovering {
                    HStack(spacing: 12) {
                        Spacer()

                        VStack(spacing: 8) {
                            MoodBoardQuickActionButton(icon: "pencil", color: .blue)
                            MoodBoardQuickActionButton(icon: "doc.on.doc", color: .green)
                            MoodBoardQuickActionButton(icon: "trash", color: .red)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial))
                    }
                    .padding(8)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(moodBoard.boardName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: moodBoard.styleCategory.iconName)
                            .foregroundColor(.blue)
                        Text(moodBoard.styleCategory.displayName)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }

                if let description = moodBoard.boardDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Label("\(moodBoard.elements.count) elements", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(moodBoard.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Tags
                if !moodBoard.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(moodBoard.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.12)))
                                .foregroundColor(.blue)
                        }
                        if moodBoard.tags.count > 3 {
                            Text("+\(moodBoard.tags.count - 3)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.12 : 0.06),
                    radius: isHovering ? 8 : 4,
                    x: 0,
                    y: isHovering ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Mood Board Quick Action Button

struct MoodBoardQuickActionButton: View {
    let icon: String
    let color: Color
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            // Action will be handled by parent
        }) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: isHovering ? 6 : 3, x: 0, y: 2))
                .scaleEffect(isHovering ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

struct MoodBoardElementPreview: View {
    let element: VisualElement
    @State private var isLoaded = false

    var body: some View {
        Group {
            switch element.elementType {
            case .color:
                // Color swatch preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(element.elementData.color ?? .gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1))

            case .image:
                // Image preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.blue.opacity(0.5)))

            case .text:
                // Text preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        Text(element.elementData.text?.prefix(20) ?? "Text")
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .padding(4))

            case .inspiration:
                // Inspiration note preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.2))
                    .overlay(
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow.opacity(0.7)))
            }
        }
        .frame(height: 80)
        .opacity(isLoaded ? 1.0 : 0)
        .scaleEffect(isLoaded ? 1.0 : 0.8)
        .animation(.easeOut(duration: 0.3), value: isLoaded)
        .onAppear {
            withAnimation {
                isLoaded = true
            }
        }
    }
}

// MARK: - Filter Chip Component

struct MoodBoardFilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isActive ? Color.blue : Color(NSColor.controlBackgroundColor)))
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyMoodBoardView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Mood Boards Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first mood board to start visualizing your wedding style")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                visualPlanningStore.showingMoodBoardCreator = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Your First Mood Board")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Spacer()
        }
    }
}

#Preview {
    MoodBoardListView()
        .environmentObject(VisualPlanningStoreV2())
        .frame(width: 800, height: 600)
}
