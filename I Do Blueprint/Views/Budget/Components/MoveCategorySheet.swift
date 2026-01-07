//
//  MoveCategorySheet.swift
//  I Do Blueprint
//
//  Sheet view for moving a budget category to a different parent folder
//  Supports N-level hierarchy with circular reference prevention
//

import SwiftUI

struct MoveCategorySheet: View {
    @Environment(\.dismiss) private var dismiss

    let category: BudgetCategory
    let allCategories: [BudgetCategory]
    let onMove: (UUID?) -> Void

    @State private var selectedParentId: UUID?
    @State private var expandedFolders: Set<UUID> = []

    private var validTargetFolders: [BudgetCategory] {
        // Filter out invalid targets:
        // 1. The category being moved
        // 2. Any descendants of the category being moved (would create circular reference)
        let descendantIds = getDescendantIds(of: category.id)
        return allCategories.filter { folder in
            folder.id != category.id && !descendantIds.contains(folder.id)
        }
    }

    private var rootFolders: [BudgetCategory] {
        validTargetFolders.filter { $0.parentCategoryId == nil }
            .sorted { $0.categoryName < $1.categoryName }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Current location
                    currentLocationSection

                    Divider()
                        .padding(.vertical, Spacing.sm)

                    // Target selection
                    targetSelectionSection
                }
                .padding()
            }

            Divider()

            // Footer buttons
            footer
        }
        .frame(width: 400, height: 500)
        .onAppear {
            selectedParentId = category.parentCategoryId
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Move Category")
                    .font(.headline)
                Text(category.categoryName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    // MARK: - Current Location

    private var currentLocationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Current Location")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: Spacing.sm) {
                Image(systemName: "folder.fill")
                    .foregroundColor(AppColors.Budget.allocated)

                if let parentId = category.parentCategoryId,
                   let parent = allCategories.first(where: { $0.id == parentId }) {
                    Text(buildBreadcrumb(for: parent))
                        .font(.subheadline)
                } else {
                    Text("Root (No Parent)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(Spacing.sm)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Target Selection

    private var targetSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Move To")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            // Root level option
            FolderSelectionRow(
                name: "Root (No Parent)",
                icon: "house.fill",
                color: AppColors.Budget.underBudget,
                isSelected: selectedParentId == nil,
                indentLevel: 0
            ) {
                selectedParentId = nil
            }

            // Hierarchical folder list
            ForEach(rootFolders) { folder in
                folderRow(for: folder, indentLevel: 0)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button("Move") {
                onMove(selectedParentId)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(selectedParentId == category.parentCategoryId)
        }
        .padding()
    }

    // MARK: - Folder Row

    /// Recursive folder row - uses AnyView for type erasure to support recursive calls
    private func folderRow(for folder: BudgetCategory, indentLevel: Int) -> AnyView {
        let children = getChildren(of: folder.id)
        let hasChildren = !children.isEmpty
        let isExpanded = expandedFolders.contains(folder.id)

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.xs) {
                    // Expand/collapse button for folders with children
                    if hasChildren {
                        Button {
                            toggleExpanded(folder.id)
                        } label: {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer()
                            .frame(width: 16)
                    }

                    FolderSelectionRow(
                        name: folder.categoryName,
                        icon: "folder.fill",
                        color: Color(hex: folder.color) ?? AppColors.Budget.allocated,
                        isSelected: selectedParentId == folder.id,
                        indentLevel: indentLevel
                    ) {
                        selectedParentId = folder.id
                    }
                }

                // Show children if expanded
                if hasChildren && isExpanded {
                    ForEach(children) { child in
                        folderRow(for: child, indentLevel: indentLevel + 1)
                    }
                }
            }
        )
    }

    // MARK: - Helpers

    private func getChildren(of parentId: UUID) -> [BudgetCategory] {
        validTargetFolders
            .filter { $0.parentCategoryId == parentId }
            .sorted { $0.categoryName < $1.categoryName }
    }

    private func getDescendantIds(of categoryId: UUID) -> Set<UUID> {
        var descendants: Set<UUID> = []
        var queue = allCategories.filter { $0.parentCategoryId == categoryId }

        while !queue.isEmpty {
            let current = queue.removeFirst()
            descendants.insert(current.id)
            queue.append(contentsOf: allCategories.filter { $0.parentCategoryId == current.id })
        }

        return descendants
    }

    private func buildBreadcrumb(for category: BudgetCategory) -> String {
        var path: [String] = [category.categoryName]
        var current: BudgetCategory? = category

        while let parentId = current?.parentCategoryId,
              let parent = allCategories.first(where: { $0.id == parentId }) {
            path.insert(parent.categoryName, at: 0)
            current = parent
        }

        return path.joined(separator: " > ")
    }

    private func toggleExpanded(_ id: UUID) {
        if expandedFolders.contains(id) {
            expandedFolders.remove(id)
        } else {
            expandedFolders.insert(id)
        }
    }
}

// MARK: - Folder Selection Row

private struct FolderSelectionRow: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let indentLevel: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            .padding(.leading, CGFloat(indentLevel) * 20)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
