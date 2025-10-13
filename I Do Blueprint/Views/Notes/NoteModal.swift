//
//  NoteModal.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import MarkdownUI
import Supabase
import SwiftUI

struct NoteModal: View {
    let note: Note?
    let onSave: (NoteInsertData) async -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: NoteRelatedType?
    @State private var selectedEntityId: String?
    @State private var availableEntities: [(id: String, name: String)] = []
    @State private var isLoadingEntities = false
    @State private var isSaving = false

    private let logger = AppLogger.ui
    @State private var showPreview = false

    private let characterLimit = 10000

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title Section
                    titleSection

                    // Type Section
                    typeSection

                    // Content Section
                    contentSection

                    // Character Count
                    characterCountSection
                }
                .padding()
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .onAppear {
                loadNoteData()
            }
        }
        .frame(width: 700, height: 600)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Title")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Add title (optional)...", text: $title)
                .textFieldStyle(.roundedBorder)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Type Section

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related To")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Type", selection: $selectedType) {
                Text("General Note").tag(NoteRelatedType?.none)

                Divider()

                ForEach(NoteRelatedType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                        Text(type.displayName)
                    }
                    .tag(NoteRelatedType?.some(type))
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
            .onChange(of: selectedType) { oldType, newType in
                // Only clear the selected entity if the type actually changed
                if oldType != newType {
                    selectedEntityId = nil
                    availableEntities = []
                    if newType != nil {
                        Task {
                            await loadEntitiesForType(newType)
                        }
                    }
                }
            }

            if selectedType != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link to Specific Item")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if isLoadingEntities {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(NSColor.controlBackgroundColor)))
                    } else if availableEntities.isEmpty {
                        Text("No \(selectedType?.displayName.lowercased() ?? "items") available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(NSColor.controlBackgroundColor)))
                    } else {
                        Picker("Select Item", selection: $selectedEntityId) {
                            Text("None").tag(String?.none)

                            ForEach(availableEntities, id: \.id) { entity in
                                Text(entity.name).tag(String?.some(entity.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(NSColor.controlBackgroundColor)))
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Content")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Preview Toggle
                Picker("Mode", selection: $showPreview) {
                    Label("Edit", systemImage: "pencil").tag(false)
                    Label("Preview", systemImage: "eye").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            // Markdown Formatting Toolbar
            if !showPreview {
                markdownToolbar
            }

            // Content Editor or Preview
            if showPreview {
                ScrollView {
                    Markdown(content)
                        .markdownTheme(.gitHub)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(minHeight: 250)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1))
            } else {
                TextEditor(text: $content)
                    .font(.body)
                    .frame(minHeight: 250)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .onChange(of: content) { _, newValue in
                        if newValue.count > characterLimit {
                            content = String(newValue.prefix(characterLimit))
                        }
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Markdown Toolbar

    private var markdownToolbar: some View {
        HStack(spacing: 8) {
            ToolbarButton(icon: "bold", tooltip: "Bold") {
                insertMarkdown("**", "**")
            }

            ToolbarButton(icon: "italic", tooltip: "Italic") {
                insertMarkdown("*", "*")
            }

            ToolbarButton(icon: "strikethrough", tooltip: "Strikethrough") {
                insertMarkdown("~~", "~~")
            }

            Divider().frame(height: 20)

            ToolbarButton(icon: "number", tooltip: "Heading") {
                insertMarkdown("## ", "")
            }

            ToolbarButton(icon: "list.bullet", tooltip: "Bullet List") {
                insertMarkdown("- ", "")
            }

            ToolbarButton(icon: "list.number", tooltip: "Numbered List") {
                insertMarkdown("1. ", "")
            }

            Divider().frame(height: 20)

            ToolbarButton(icon: "link", tooltip: "Link") {
                insertMarkdown("[", "](url)")
            }

            ToolbarButton(icon: "photo", tooltip: "Image") {
                insertMarkdown("![alt text](", ")")
            }

            ToolbarButton(icon: "chevron.left.slash.chevron.right", tooltip: "Code") {
                insertMarkdown("`", "`")
            }

            ToolbarButton(icon: "quote.opening", tooltip: "Quote") {
                insertMarkdown("> ", "")
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
    }

    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        let newText = content + prefix + suffix
        if newText.count <= characterLimit {
            content = newText
        }
    }

    // MARK: - Character Count Section

    private var characterCountSection: some View {
        HStack {
            Spacer()

            HStack(spacing: 4) {
                Text("\(content.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(content.count > characterLimit * 9 / 10 ? .orange : .secondary)

                Text("/ \(characterLimit) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            content.count <= characterLimit
    }

    private func loadNoteData() {
        guard let note else { return }

        title = note.title ?? ""
        content = note.content
        selectedType = note.relatedType

        // Store the related ID temporarily
        let savedRelatedId = note.relatedId

        if let type = note.relatedType {
            Task {
                await loadEntitiesForType(type)
                // Set the selected entity AFTER entities are loaded
                if let savedId = savedRelatedId {
                    selectedEntityId = savedId
                }
            }
        }
    }

    private func loadEntitiesForType(_ type: NoteRelatedType?) async {
        guard let type else { return }

        isLoadingEntities = true
        defer { isLoadingEntities = false }

        do {
            let supabase = SupabaseManager.shared.client

            switch type {
            case .vendor:
                struct VendorResult: Decodable {
                    let id: Int64
                    let vendorName: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case vendorName = "vendor_name"
                    }
                }

                let vendors: [VendorResult] = try await supabase
                    .from("vendorInformation")
                    .select("id, vendor_name")
                    .order("vendor_name", ascending: true)
                    .execute()
                    .value

                availableEntities = vendors.map { (id: String($0.id), name: $0.vendorName) }

            case .guest:
                struct GuestResult: Decodable {
                    let id: UUID
                    let firstName: String
                    let lastName: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case firstName = "first_name"
                        case lastName = "last_name"
                    }
                }

                let guests: [GuestResult] = try await supabase
                    .from("guest_list")
                    .select("id, first_name, last_name")
                    .order("first_name", ascending: true)
                    .execute()
                    .value

                availableEntities = guests.map { (id: $0.id.uuidString, name: "\($0.firstName) \($0.lastName)") }

            case .task:
                struct TaskResult: Decodable {
                    let id: UUID
                    let taskName: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case taskName = "task_name"
                    }
                }

                let tasks: [TaskResult] = try await supabase
                    .from("tasks")
                    .select("id, task_name")
                    .order("task_name", ascending: true)
                    .execute()
                    .value

                availableEntities = tasks.map { (id: $0.id.uuidString, name: $0.taskName) }

            case .milestone:
                struct MilestoneResult: Decodable {
                    let id: UUID
                    let milestoneName: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case milestoneName = "milestone_name"
                    }
                }

                let milestones: [MilestoneResult] = try await supabase
                    .from("milestones")
                    .select("id, milestone_name")
                    .order("milestone_name", ascending: true)
                    .execute()
                    .value

                availableEntities = milestones.map { (id: $0.id.uuidString, name: $0.milestoneName) }

            case .budget:
                struct BudgetResult: Decodable {
                    let id: UUID
                    let categoryName: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case categoryName = "category_name"
                    }
                }

                let categories: [BudgetResult] = try await supabase
                    .from("budget_categories")
                    .select("id, category_name")
                    .order("category_name", ascending: true)
                    .execute()
                    .value

                availableEntities = categories.map { (id: $0.id.uuidString, name: $0.categoryName) }

            case .visualElement:
                struct VisualResult: Decodable {
                    let id: UUID
                    let elementName: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case elementName = "element_name"
                    }
                }

                let elements: [VisualResult] = try await supabase
                    .from("visual_planning")
                    .select("id, element_name")
                    .order("element_name", ascending: true)
                    .execute()
                    .value

                availableEntities = elements.map { (id: $0.id.uuidString, name: $0.elementName) }

            case .payment:
                struct PaymentResult: Decodable {
                    let id: Int64
                    let paymentDescription: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case paymentDescription = "payment_description"
                    }
                }

                let payments: [PaymentResult] = try await supabase
                    .from("paymentPlans")
                    .select("id, payment_description")
                    .order("payment_description", ascending: true)
                    .execute()
                    .value

                availableEntities = payments.map { (id: String($0.id), name: $0.paymentDescription) }

            case .document:
                struct DocumentResult: Decodable {
                    let id: UUID
                    let fileName: String

                    enum CodingKeys: String, CodingKey {
                        case id
                        case fileName = "file_name"
                    }
                }

                let documents: [DocumentResult] = try await supabase
                    .from("documents")
                    .select("id, file_name")
                    .order("file_name", ascending: true)
                    .execute()
                    .value

                availableEntities = documents.map { (id: $0.id.uuidString, name: $0.fileName) }
            }
        } catch {
            logger.error("Failed to load entities for type \(type)", error: error)
            availableEntities = []
        }
    }

    private func saveNote() {
        isSaving = true

        // Get couple ID from settings
        guard let coupleId = settingsViewModel.coupleId else {
            logger.warning("No couple ID available - user not authenticated")
            isSaving = false
            return
        }

        let noteData = NoteInsertData(
            coupleId: coupleId,
            title: title.isEmpty ? nil : title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            relatedType: selectedType,
            relatedId: selectedEntityId)

        Task {
            await onSave(noteData)
            dismiss()
        }
    }
}

// MARK: - Toolbar Button Component

struct ToolbarButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor)))
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

// MARK: - Preview

#Preview {
    NoteModal(
        note: nil,
        onSave: { _ in },
        onCancel: {})
}
