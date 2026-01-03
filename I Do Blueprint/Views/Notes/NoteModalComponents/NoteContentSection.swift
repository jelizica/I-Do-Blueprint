//
//  NoteContentSection.swift
//  I Do Blueprint
//
//  Component for note content editor with markdown support
//

import SwiftUI
import MarkdownUI

struct NoteContentSection: View {
    @Binding var content: String
    @Binding var showPreview: Bool
    let characterLimit: Int
    let onInsertMarkdown: (String, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            header
            
            if !showPreview {
                MarkdownToolbar(onInsert: onInsertMarkdown)
            }
            
            contentArea
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.controlBackground)
        )
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack {
            Text("Content")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Picker("Mode", selection: $showPreview) {
                Label("Edit", systemImage: "pencil").tag(false)
                Label("Preview", systemImage: "eye").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
    }
    
    @ViewBuilder
    private var contentArea: some View {
        if showPreview {
            previewView
        } else {
            editorView
        }
    }
    
    private var previewView: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(.gitHub)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .frame(minHeight: 250)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 1)
        )
    }
    
    private var editorView: some View {
        TextEditor(text: $content)
            .font(.body)
            .frame(minHeight: 250)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 1)
            )
            .onChange(of: content) { _, newValue in
                if newValue.count > characterLimit {
                    content = String(newValue.prefix(characterLimit))
                }
            }
    }
}

#Preview {
    NoteContentSection(
        content: .constant("# Sample Note\n\nThis is **bold** and this is *italic*."),
        showPreview: .constant(false),
        characterLimit: 10000,
        onInsertMarkdown: { _, _ in }
    )
    .padding()
}
