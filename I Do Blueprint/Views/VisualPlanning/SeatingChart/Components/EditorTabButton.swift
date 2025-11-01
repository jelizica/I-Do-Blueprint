//
//  EditorTabButton.swift
//  My Wedding Planning App
//
//  Tab button component for seating chart editor navigation
//

import SwiftUI

struct EditorTabButton: View {
    let tab: EditorTab
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.body)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundColor(isSelected ? .primary : .secondary)

                    if let count {
                        Text("\(count) \(count == 1 ? "item" : "items")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ? Color.blue.opacity(0.12) : (isHovering ? AppColors.textSecondary.opacity(0.08) : Color.clear)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1))
            .scaleEffect(isHovering && !isSelected ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
