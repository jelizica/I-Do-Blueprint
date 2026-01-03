//
//  MarkdownToolbar.swift
//  I Do Blueprint
//
//  Component for markdown formatting toolbar
//

import SwiftUI

struct MarkdownToolbar: View {
    let onInsert: (String, String) -> Void
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            textFormattingButtons
            
            Divider().frame(height: 20)
            
            structureButtons
            
            Divider().frame(height: 20)
            
            mediaButtons
            
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.controlBackground.opacity(0.5))
        )
    }
    
    // MARK: - Button Groups
    
    private var textFormattingButtons: some View {
        Group {
            MarkdownToolbarButton(icon: "bold", tooltip: "Bold") {
                onInsert("**", "**")
            }
            
            MarkdownToolbarButton(icon: "italic", tooltip: "Italic") {
                onInsert("*", "*")
            }
            
            MarkdownToolbarButton(icon: "strikethrough", tooltip: "Strikethrough") {
                onInsert("~~", "~~")
            }
        }
    }
    
    private var structureButtons: some View {
        Group {
            MarkdownToolbarButton(icon: "number", tooltip: "Heading") {
                onInsert("## ", "")
            }
            
            MarkdownToolbarButton(icon: "list.bullet", tooltip: "Bullet List") {
                onInsert("- ", "")
            }
            
            MarkdownToolbarButton(icon: "list.number", tooltip: "Numbered List") {
                onInsert("1. ", "")
            }
        }
    }
    
    private var mediaButtons: some View {
        Group {
            MarkdownToolbarButton(icon: "link", tooltip: "Link") {
                onInsert("[", "](url)")
            }
            
            MarkdownToolbarButton(icon: "photo", tooltip: "Image") {
                onInsert("![alt text](", ")")
            }
            
            MarkdownToolbarButton(icon: "chevron.left.slash.chevron.right", tooltip: "Code") {
                onInsert("`", "`")
            }
            
            MarkdownToolbarButton(icon: "quote.opening", tooltip: "Quote") {
                onInsert("> ", "")
            }
        }
    }
}

// MARK: - Markdown Toolbar Button

struct MarkdownToolbarButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.controlBackground)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

#Preview {
    MarkdownToolbar(onInsert: { _, _ in })
        .padding()
}
