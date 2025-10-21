//
//  TimelineItemModal.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TimelineItemModal: View {
    let item: TimelineItem?
    let onSave: (TimelineItemInsertData) async -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @State private var title = ""
    @State private var description = ""
    @State private var itemType: TimelineItemType = .task
    @State private var itemDate = Date()
    @State private var completed = false
    @State private var isSaving = false

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info Section
                    basicInfoSection

                    // Date Section
                    dateSection

                    // Description Section
                    descriptionSection
                }
                .padding()
            }
            .navigationTitle(item == nil ? "New Timeline Item" : "Edit Timeline Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .onAppear {
                loadItemData()
            }
        }
        .frame(width: 600, height: 500)
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Enter title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                // Type
                VStack(alignment: .leading, spacing: 6) {
                    Text("Type")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("Type", selection: $itemType) {
                        ForEach(TimelineItemType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: typeIcon(type))
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Completed Toggle
                Toggle("Completed", isOn: $completed)
                    .fontWeight(.medium)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date")
                .font(.headline)
                .fontWeight(.semibold)

            DatePicker("Item Date", selection: $itemDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Add description (optional)...", text: $description, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(5 ... 10)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func typeIcon(_ type: TimelineItemType) -> String {
        switch type {
        case .task: "checklist"
        case .milestone: "star.fill"
        case .vendorEvent: "person.2.fill"
        case .payment: "dollarsign.circle.fill"
        case .reminder: "bell.fill"
        case .ceremony: "heart.fill"
        case .other: "circle.fill"
        }
    }

    private func loadItemData() {
        guard let item else { return }

        title = item.title
        description = item.description ?? ""
        itemType = item.itemType
        itemDate = item.itemDate
        completed = item.completed
    }

    private func saveItem() {
        isSaving = true

        // Get couple ID from settings
        guard let coupleId = settingsStore.coupleId else {
            logger.warning("No couple ID available - user not authenticated")
            isSaving = false
            return
        }

        let itemData = TimelineItemInsertData(
            coupleId: coupleId,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            itemType: itemType,
            itemDate: itemDate,
            endDate: nil,
            completed: completed,
            relatedId: nil)

        Task {
            await onSave(itemData)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    TimelineItemModal(
        item: nil,
        onSave: { _ in },
        onCancel: {})
}
