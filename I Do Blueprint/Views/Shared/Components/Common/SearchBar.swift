//
//  SearchBar.swift
//  I Do Blueprint
//
//  Reusable search bar component
//

import SwiftUI

/// Standard search bar with clear button
struct SearchBar: View {
    private let logger = AppLogger.ui
    @Binding var text: String
    let placeholder: String
    let onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(.body)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }
                .accessibilityLabel("Search")
                .accessibilityHint(placeholder)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(AppColors.contentBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isFocused ? AppColors.primary : AppColors.border, lineWidth: 1)
        )
    }
}

/// Compact search bar for toolbars
struct CompactSearchBar: View {
    @Binding var text: String
    let placeholder: String

    @FocusState private var isFocused: Bool
    @State private var isExpanded = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if isExpanded {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.callout)

                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .frame(width: 200)

                    if !text.isEmpty {
                        Button(action: {
                            text = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                                .font(.callout)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(AppColors.contentBackground)
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                Button(action: {
                    withAnimation(AnimationStyle.spring) {
                        isExpanded = true
                        isFocused = true
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused && text.isEmpty {
                withAnimation(AnimationStyle.spring) {
                    isExpanded = false
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Search Bar") {
    VStack(spacing: Spacing.lg) {
        SearchBar(
            text: .constant(""),
            placeholder: "Search guests..."
        )

        SearchBar(
            text: .constant("John"),
            placeholder: "Search guests..."
        )

        SearchBar(
            text: .constant(""),
            placeholder: "Search vendors...",
            onSubmit: {
                // TODO: Implement action - print("Search submitted")
            }
        )
    }
    .padding()
}

#Preview("Compact Search Bar") {
    HStack {
        Spacer()
        CompactSearchBar(
            text: .constant(""),
            placeholder: "Search..."
        )
    }
    .padding()
}
