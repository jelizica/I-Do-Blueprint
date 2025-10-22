//
//  MoodBoardDetailsView.swift
//  I Do Blueprint
//
//  Generate detailed mood board export with element descriptions
//

import SwiftUI

struct MoodBoardDetailsView: View {
    let moodBoard: MoodBoard
    let branding: BrandingSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Title
            Text(moodBoard.boardName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(branding.textColor)
            
            // Description
            if let description = moodBoard.boardDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(branding.textColor.opacity(0.8))
            }
            
            Divider()
            
            // Elements breakdown
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Elements (\(moodBoard.elements.count))")
                    .font(.headline)
                    .foregroundColor(branding.textColor)
                
                ForEach(Array(moodBoard.elements.enumerated()), id: \.offset) { index, element in
                    ElementDetailRow(
                        element: element,
                        index: index + 1,
                        textColor: branding.textColor
                    )
                }
            }
            
            Divider()
            
            // Color analysis
            if !extractedColors.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Color Palette")
                        .font(.headline)
                        .foregroundColor(branding.textColor)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(Array(extractedColors.enumerated()), id: \.offset) { _, color in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                    )
                                
                                Text(color.hexString)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(branding.textColor.opacity(0.7))
                            }
        }
                    }
                }
            }
            
            // Style notes
            if let notes = moodBoard.notes, !notes.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Style Notes")
                        .font(.headline)
                        .foregroundColor(branding.textColor)
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(branding.textColor.opacity(0.8))
                }
            }
            
            // Tags
            if !moodBoard.tags.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(branding.textColor)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(moodBoard.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(branding.primaryColor.opacity(0.1))
                                )
                                .foregroundColor(branding.primaryColor)
                        }
                    }
                }
            }
            
            // Inspiration sources
            if !moodBoard.inspirationUrls.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Inspiration Sources")
                        .font(.headline)
                        .foregroundColor(branding.textColor)
                    
                    ForEach(moodBoard.inspirationUrls, id: \.self) { url in
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.caption2)
                                .foregroundColor(branding.primaryColor)
                            
                            Text(url)
                                .font(.caption)
                                .foregroundColor(branding.primaryColor)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var extractedColors: [Color] {
        // Extract unique colors from elements
        var colorSet: Set<String> = []
        var colors: [Color] = []
        
        for element in moodBoard.elements {
            // Extract color from element data
            if let color = element.elementData.color {
                let hexString = color.hexString
                if !colorSet.contains(hexString) {
                    colorSet.insert(hexString)
                    colors.append(color)
                }
            }
        }
        
        return Array(colors.prefix(8))
    }
}

// MARK: - Element Detail Row

struct ElementDetailRow: View {
    let element: VisualElement
    let index: Int
    let textColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index).")
                .font(.caption)
                .foregroundColor(textColor.opacity(0.6))
                .frame(width: 30, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(element.elementType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                if let description = element.notes, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.7))
                }
                
                // Element-specific details
                elementSpecificDetails
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var elementSpecificDetails: some View {
        switch element.elementType {
        case .image:
            if let imageURL = element.elementData.imageUrl {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Text("Source: \(URL(string: imageURL)?.lastPathComponent ?? imageURL)")
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            
        case .text:
            if let text = element.elementData.text, !text.isEmpty {
                Text("\"\(text)\"")
                    .font(.caption)
                    .italic()
                    .foregroundColor(textColor.opacity(0.7))
            }
            
        case .color:
            if let color = element.elementData.color {
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                    
                    Text(color.hexString)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            
        case .inspiration:
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.5))
                
                Text("Inspiration element")
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    MoodBoardDetailsView(
        moodBoard: {
            var board = MoodBoard(
                tenantId: "preview",
                boardName: "Romantic Garden Wedding",
                boardDescription: "A dreamy outdoor celebration with soft pastels and natural elements",
                styleCategory: .romantic
            )
            board.notes = "Focus on soft, flowing fabrics and delicate floral arrangements. Keep the color palette muted and romantic."
            board.tags = ["romantic", "garden", "outdoor", "spring", "pastels"]
            board.inspirationUrls = ["https://pinterest.com/example1", "https://instagram.com/example2"]
            return board
        }(),
        branding: BrandingSettings()
    )
    .frame(width: 600, height: 800)
}
