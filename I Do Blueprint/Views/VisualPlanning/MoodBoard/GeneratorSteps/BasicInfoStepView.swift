//
//  BasicInfoStepView.swift
//  My Wedding Planning App
//
//  Basic information step for mood board generator
//

import SwiftUI

struct BasicInfoStepView: View {
    @Binding var state: MoodBoardGeneratorState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("Basic Information")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Let's start by setting up your mood board's basic details")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 20) {
                    // Board Name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mood Board Name", systemImage: "textformat")
                            .font(.headline)

                        TextField("e.g., Romantic Garden Wedding", text: $state.boardName)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)

                        Text("Give your mood board a descriptive name that captures its essence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Board Description
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description (Optional)", systemImage: "text.alignleft")
                            .font(.headline)

                        TextField(
                            "Describe the vision for your mood board...",
                            text: $state.boardDescription,
                            axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3 ... 6)

                        Text("Optional description to help remember the inspiration behind this board")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Style Category Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Wedding Style", systemImage: "star.square")
                            .font(.headline)

                        Text("Choose the primary style that best represents your vision")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
                        ], spacing: 16) {
                            ForEach(StyleCategory.allCases, id: \.self) { style in
                                StyleCategoryCard(
                                    style: style,
                                    isSelected: state.styleCategory == style) {
                                    state.styleCategory = style
                                }
                            }
                        }
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tags (Optional)", systemImage: "tag")
                            .font(.headline)

                        TagInputView(tags: $state.tags)

                        Text("Add tags to help organize and find your mood boards later")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 20)
        }
    }
}

struct TagInputView: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Input field
            HStack {
                TextField("Add a tag...", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTag()
                    }

                Button("Add") {
                    addTag()
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Tag display
            if !tags.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: 8)
                ], spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            removeTag(tag)
                        }
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else { return }

        tags.append(trimmedTag)
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

extension StyleCategory {
    var iconColor: Color {
        switch self {
        case .modern: .blue
        case .classic: .purple
        case .rustic: .brown
        case .bohemian: .pink
        case .vintage: .orange
        case .romantic: .red
        case .minimalist: .gray
        case .industrial: .black
        case .garden: .green
        case .beach: .cyan
        case .mountain: .indigo
        case .urban: .primary
        case .destination: .mint
        case .cultural: .yellow
        case .seasonal: .teal
        case .custom: .secondary
        case .glamorous: .pink
        case .beachCoastal: .cyan
        }
    }
}

#Preview {
    @State var sampleState = MoodBoardGeneratorState()

    return BasicInfoStepView(state: $sampleState)
        .frame(width: 800, height: 600)
}
