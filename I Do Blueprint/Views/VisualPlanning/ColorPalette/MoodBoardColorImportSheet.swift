//
//  MoodBoardColorImportSheet.swift
//  I Do Blueprint
//
//  Sheet for importing colors from existing mood boards
//

import SwiftUI

struct MoodBoardColorImportSheet: View {
    let moodBoards: [MoodBoard]
    let onImport: ([Color]) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedMoodBoardId: UUID?
    @State private var extractedColors: [Color] = []
    @State private var selectedColors: Set<String> = []
    
    private let logger = AppLogger.ui
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Content
            HStack(spacing: 0) {
                // Mood board list
                moodBoardListSection
                
                Divider()
                
                // Extracted colors
                extractedColorsSection
            }
            
            Divider()
            
            // Footer
            footerSection
        }
        .frame(width: 700, height: 500)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("Import Colors from Mood Board")
                .font(Typography.heading)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Mood Board List Section
    
    private var moodBoardListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Select Mood Board")
                .font(Typography.subheading)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ForEach(moodBoards, id: \.id) { moodBoard in
                        MoodBoardRow(
                            moodBoard: moodBoard,
                            isSelected: selectedMoodBoardId == moodBoard.id,
                            onSelect: {
                                selectMoodBoard(moodBoard)
                            })
                    }
                }
                .padding()
            }
        }
        .frame(width: 300)
    }
    
    // MARK: - Extracted Colors Section
    
    private var extractedColorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if extractedColors.isEmpty {
                VStack {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Select a mood board to extract colors")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("Extracted Colors")
                            .font(Typography.subheading)
                        
                        Spacer()
                        
                        Text("\(selectedColors.count) selected")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.md) {
                            ForEach(extractedColors, id: \.hexString) { color in
                                ColorSelectionCard(
                                    color: color,
                                    isSelected: selectedColors.contains(color.hexString),
                                    onToggle: {
                                        toggleColorSelection(color)
                                    })
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Import \(selectedColors.count) Colors") {
                let colorsToImport = extractedColors.filter { selectedColors.contains($0.hexString) }
                onImport(colorsToImport)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedColors.isEmpty)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func selectMoodBoard(_ moodBoard: MoodBoard) {
        selectedMoodBoardId = moodBoard.id
        extractColors(from: moodBoard)
    }
    
    private func extractColors(from moodBoard: MoodBoard) {
        extractedColors = []
        selectedColors = []
        
        var colors: [Color] = []
        
        // Add background color
        colors.append(moodBoard.backgroundColor)
        
        // Extract colors from elements
        for element in moodBoard.elements {
            switch element.elementType {
            case .color:
                if let color = element.elementData.color {
                    colors.append(color)
                }
            default:
                break
            }
        }
        
        // Remove duplicates and limit to 20 colors
        let uniqueColors = Array(Set(colors.map { $0.hexString }))
            .compactMap { Color(hex: $0) }
            .prefix(20)
        
        extractedColors = Array(uniqueColors)
        
        logger.info("Extracted \(extractedColors.count) colors from mood board: \(moodBoard.boardName)")
    }
    
    private func toggleColorSelection(_ color: Color) {
        if selectedColors.contains(color.hexString) {
            selectedColors.remove(color.hexString)
        } else {
            selectedColors.insert(color.hexString)
        }
    }
}

// MARK: - Mood Board Row

struct MoodBoardRow: View {
    let moodBoard: MoodBoard
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(moodBoard.boardName)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(moodBoard.elements.count) elements")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding()
            .background(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select mood board \(moodBoard.boardName)")
    }
}

// MARK: - Color Selection Card

struct ColorSelectionCard: View {
    let color: Color
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? AppColors.primary : AppColors.textPrimary.opacity(0.1), lineWidth: isSelected ? 3 : 1))
                
                Text(color.hexString)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "Deselect color \(color.hexString)" : "Select color \(color.hexString)")
    }
}

// MARK: - Preview

#Preview {
    MoodBoardColorImportSheet(
        moodBoards: [],
        onImport: { _ in },
        onDismiss: {})
}
