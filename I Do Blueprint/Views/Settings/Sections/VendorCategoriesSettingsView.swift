//
//  VendorCategoriesSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct VendorCategoriesSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    @State private var showAddCategory = false
    @State private var editingCategory: CustomVendorCategory?
    @State private var categoryToDelete: CustomVendorCategory?
    @State private var vendorsUsingCategory: [String] = []
    @State private var showVendorUsageAlert = false
    @State private var deletionError: String?

    // Standard vendor categories
    private let standardCategories = [
        "Venue",
        "Catering",
        "Photography",
        "Videography",
        "Music & Entertainment",
        "Florist",
        "Baker",
        "Attire",
        "Hair & Makeup",
        "Stationery",
        "Transportation",
        "Accommodation",
        "Officiant",
        "Rentals",
        "Planner/Coordinator",
        "Jewelry",
        "Favors & Gifts",
        "Other Services"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Vendor Categories",
                subtitle: "Manage standard and custom vendor categories",
                sectionName: "vendors",
                isSaving: viewModel.savingSections.contains("vendors"),
                hasUnsavedChanges: viewModel.localSettings.vendors != viewModel.settings.vendors,
                onSave: {
                    Task {
                        await viewModel.saveVendorsSettings()
                    }
                })

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Standard Categories
                    GroupBox(label: HStack {
                        Image(systemName: "list.bullet")
                        Text("Standard Categories")
                            .font(.headline)
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(
                                "Hide categories you don't need. Hidden categories won't appear in vendor creation forms.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, Spacing.sm)

                            ForEach(standardCategories, id: \.self) { category in
                                StandardCategoryRow(
                                    category: category,
                                    isHidden: viewModel.localSettings.vendors.hiddenStandardCategories?
                                        .contains(category) ?? false,
                                    onToggle: { toggleStandardCategory(category) })
                            }
                        }
                        .padding()
                    }

                    // Custom Categories
                    GroupBox(label: HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Custom Categories")
                            .font(.headline)
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Create custom categories for specialized vendors not covered by standard options.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if viewModel.customVendorCategories.isEmpty {
                                Text("No custom categories created")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(viewModel.customVendorCategories) { category in
                                    CustomCategoryRow(
                                        category: category,
                                        onEdit: { editingCategory = category },
                                        onDelete: { checkAndDeleteCategory(category) })
                                }
                            }

                            if let error = deletionError {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }

                            Button(action: { showAddCategory = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Custom Category")
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCustomCategorySheet(
                viewModel: viewModel,
                existingCategories: allCategoryNames(),
                onCancel: { showAddCategory = false })
        }
        .sheet(item: $editingCategory) { category in
            EditCustomCategorySheet(
                category: category,
                viewModel: viewModel,
                existingCategories: allCategoryNames().filter { $0 != category.name },
                onCancel: { editingCategory = nil })
        }
        .alert("Category In Use", isPresented: $showVendorUsageAlert) {
            Button("OK") {
                categoryToDelete = nil
                vendorsUsingCategory = []
            }
        } message: {
            if vendorsUsingCategory.isEmpty {
                Text("This category cannot be deleted.")
            } else {
                Text(
                    "This category is used by the following vendors:\n\n\(vendorsUsingCategory.joined(separator: "\n"))\n\nPlease reassign or delete these vendors before removing this category.")
            }
        }
    }

    private func toggleStandardCategory(_ category: String) {
        if viewModel.localSettings.vendors.hiddenStandardCategories == nil {
            viewModel.localSettings.vendors.hiddenStandardCategories = []
        }

        if let index = viewModel.localSettings.vendors.hiddenStandardCategories?.firstIndex(of: category) {
            viewModel.localSettings.vendors.hiddenStandardCategories?.remove(at: index)
        } else {
            viewModel.localSettings.vendors.hiddenStandardCategories?.append(category)
        }
    }

    private func allCategoryNames() -> [String] {
        var names = standardCategories
        names.append(contentsOf: viewModel.customVendorCategories.map(\.name))
        return names
    }

    private func checkAndDeleteCategory(_ category: CustomVendorCategory) {
        deletionError = nil
        categoryToDelete = category

        Task {
            do {
                let vendors = try await viewModel.checkVendorsUsingCategory(categoryId: category.id)

                if vendors.isEmpty {
                    // Safe to delete
                    try await viewModel.deleteCustomCategory(id: category.id)
                } else {
                    // Show vendors using this category
                    vendorsUsingCategory = vendors.map(\.vendorName)
                    showVendorUsageAlert = true
                }
            } catch {
                deletionError = "Failed to check category usage: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Standard Category Row

struct StandardCategoryRow: View {
    let category: String
    let isHidden: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: isHidden ? "eye.slash" : "eye")
                .foregroundColor(isHidden ? .secondary : .blue)
                .frame(width: 24)

            Text(category)
                .foregroundColor(isHidden ? .secondary : .primary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { !isHidden },
                set: { _ in onToggle() }))
                .labelsHidden()
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Custom Category Row

struct CustomCategoryRow: View {
    let category: CustomVendorCategory
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if let description = category.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let percentage = category.typicalBudgetPercentage, !percentage.isEmpty {
                        Text("Typical budget: \(percentage)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
            }

            Divider()
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Add Custom Category Sheet

struct AddCustomCategorySheet: View {
    @ObservedObject var viewModel: SettingsStoreV2
    let existingCategories: [String]
    let onCancel: () -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var typicalBudgetPercentage = ""
    @State private var validationError: String?
    @State private var isCreating = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Category")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Category Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Drone Photography", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: name) { _, _ in
                            validationError = nil
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Brief description of this category", text: $description)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Typical Budget Percentage (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., 5-8%", text: $typicalBudgetPercentage)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let error = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button(action: handleCreate) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Create")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || isCreating)
            }
        }
        .padding()
        .frame(width: 500)
    }

    private func handleCreate() {
        // Validate name collision
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if existingCategories.contains(where: { $0.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) {
            validationError = "A category with this name already exists"
            return
        }

        if trimmedName.isEmpty {
            validationError = "Category name cannot be empty"
            return
        }

        isCreating = true
        validationError = nil

        Task {
            await viewModel.createCustomCategory(
                name: trimmedName,
                description: description.isEmpty ? nil : description,
                typicalBudgetPercentage: typicalBudgetPercentage.isEmpty ? nil : typicalBudgetPercentage)
            isCreating = false

            if viewModel.error == nil {
                onCancel()
            } else {
                validationError = viewModel.error?.localizedDescription
            }
        }
    }
}

// MARK: - Edit Custom Category Sheet

struct EditCustomCategorySheet: View {
    let category: CustomVendorCategory
    @ObservedObject var viewModel: SettingsStoreV2
    let existingCategories: [String]
    let onCancel: () -> Void

    @State private var name: String
    @State private var description: String
    @State private var typicalBudgetPercentage: String
    @State private var validationError: String?
    @State private var isSaving = false

    init(
        category: CustomVendorCategory,
        viewModel: SettingsStoreV2,
        existingCategories: [String],
        onCancel: @escaping () -> Void) {
        self.category = category
        self.viewModel = viewModel
        self.existingCategories = existingCategories
        self.onCancel = onCancel
        _name = State(initialValue: category.name)
        _description = State(initialValue: category.description ?? "")
        _typicalBudgetPercentage = State(initialValue: category.typicalBudgetPercentage ?? "")
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Category")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Category Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Category Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: name) { _, _ in
                            validationError = nil
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Description", text: $description)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Typical Budget Percentage (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., 5-8%", text: $typicalBudgetPercentage)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let error = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button(action: handleSave) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Save")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || isSaving)
            }
        }
        .padding()
        .frame(width: 500)
    }

    private func handleSave() {
        // Validate name collision
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if existingCategories.contains(where: { $0.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) {
            validationError = "A category with this name already exists"
            return
        }

        if trimmedName.isEmpty {
            validationError = "Category name cannot be empty"
            return
        }

        isSaving = true
        validationError = nil

        Task {
            await viewModel.updateCustomCategory(
                id: category.id,
                name: trimmedName != category.name ? trimmedName : nil,
                description: description != (category.description ?? "") ? description : nil,
                typicalBudgetPercentage: typicalBudgetPercentage != (category.typicalBudgetPercentage ?? "") ?
                    typicalBudgetPercentage : nil)
            isSaving = false

            if viewModel.error == nil {
                onCancel()
            } else {
                validationError = viewModel.error?.localizedDescription
            }
        }
    }
}

#Preview {
    VendorCategoriesSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 800, height: 700)
}
