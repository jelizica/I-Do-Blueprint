//
//  NoteModalV2.swift
//  I Do Blueprint
//
//  Refactored note modal with reduced complexity and nesting
//  Decomposed into focused components following best practices
//

import SwiftUI
import Supabase

struct NoteModalV2: View {
    let note: Note?
    let onSave: (NoteInsertData) async -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    
    // MARK: - State
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: NoteRelatedType?
    @State private var selectedEntityId: String?
    @State private var availableEntities: [(id: String, name: String)] = []
    @State private var isLoadingEntities = false
    @State private var isSaving = false
    @State private var showPreview = false
    
    private let logger = AppLogger.ui
    private let characterLimit = 10000
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    NoteTitleSection(title: $title)
                    
                    NoteTypeSection(
                        selectedType: $selectedType,
                        selectedEntityId: $selectedEntityId,
                        availableEntities: $availableEntities,
                        isLoadingEntities: $isLoadingEntities,
                        onTypeChange: loadEntitiesForType
                    )
                    
                    NoteContentSection(
                        content: $content,
                        showPreview: $showPreview,
                        characterLimit: characterLimit,
                        onInsertMarkdown: insertMarkdown
                    )
                    
                    NoteCharacterCount(
                        currentCount: content.count,
                        limit: characterLimit
                    )
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
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            content.count <= characterLimit
    }
    
    // MARK: - Data Loading
    
    private func loadNoteData() {
        guard let note else { return }
        
        title = note.title ?? ""
        content = note.content
        selectedType = note.relatedType
        
        let savedRelatedId = note.relatedId
        
        if let type = note.relatedType {
            Task {
                await loadEntitiesForType(type)
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
            guard let supabase = SupabaseManager.shared.client else {
                logger.error("Supabase client not available")
                availableEntities = []
                return
            }
            
            availableEntities = try await fetchEntitiesForType(type, supabase: supabase)
        } catch {
            logger.error("Failed to load entities for type \(type)", error: error)
            availableEntities = []
        }
    }
    
    // MARK: - Entity Fetching
    
    private func fetchEntitiesForType(
        _ type: NoteRelatedType,
        supabase: SupabaseClient
    ) async throws -> [(id: String, name: String)] {
        switch type {
        case .vendor:
            return try await fetchVendors(supabase: supabase)
        case .guest:
            return try await fetchGuests(supabase: supabase)
        case .task:
            return try await fetchTasks(supabase: supabase)
        case .milestone:
            return try await fetchMilestones(supabase: supabase)
        case .budget:
            return try await fetchBudgetCategories(supabase: supabase)
        case .visualElement:
            return try await fetchVisualElements(supabase: supabase)
        case .payment:
            return try await fetchPayments(supabase: supabase)
        case .document:
            return try await fetchDocuments(supabase: supabase)
        }
    }
    
    private func fetchVendors(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct VendorResult: Decodable {
            let id: Int64
            let vendorName: String
            enum CodingKeys: String, CodingKey {
                case id, vendorName = "vendor_name"
            }
        }
        
        let vendors: [VendorResult] = try await supabase
            .from("vendor_information")
            .select("id, vendor_name")
            .order("vendor_name", ascending: true)
            .execute()
            .value
        
        return vendors.map { (id: String($0.id), name: $0.vendorName) }
    }
    
    private func fetchGuests(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct GuestResult: Decodable {
            let id: UUID
            let firstName: String
            let lastName: String
            enum CodingKeys: String, CodingKey {
                case id, firstName = "first_name", lastName = "last_name"
            }
        }
        
        let guests: [GuestResult] = try await supabase
            .from("guest_list")
            .select("id, first_name, last_name")
            .order("first_name", ascending: true)
            .execute()
            .value
        
        return guests.map { (id: $0.id.uuidString, name: "\($0.firstName) \($0.lastName)") }
    }
    
    private func fetchTasks(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct TaskResult: Decodable {
            let id: UUID
            let taskName: String
            enum CodingKeys: String, CodingKey {
                case id, taskName = "task_name"
            }
        }
        
        let tasks: [TaskResult] = try await supabase
            .from("tasks")
            .select("id, task_name")
            .order("task_name", ascending: true)
            .execute()
            .value
        
        return tasks.map { (id: $0.id.uuidString, name: $0.taskName) }
    }
    
    private func fetchMilestones(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct MilestoneResult: Decodable {
            let id: UUID
            let milestoneName: String
            enum CodingKeys: String, CodingKey {
                case id, milestoneName = "milestone_name"
            }
        }
        
        let milestones: [MilestoneResult] = try await supabase
            .from("milestones")
            .select("id, milestone_name")
            .order("milestone_name", ascending: true)
            .execute()
            .value
        
        return milestones.map { (id: $0.id.uuidString, name: $0.milestoneName) }
    }
    
    private func fetchBudgetCategories(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct BudgetResult: Decodable {
            let id: UUID
            let categoryName: String
            enum CodingKeys: String, CodingKey {
                case id, categoryName = "category_name"
            }
        }
        
        let categories: [BudgetResult] = try await supabase
            .from("budget_categories")
            .select("id, category_name")
            .order("category_name", ascending: true)
            .execute()
            .value
        
        return categories.map { (id: $0.id.uuidString, name: $0.categoryName) }
    }
    
    private func fetchVisualElements(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct VisualResult: Decodable {
            let id: UUID
            let elementName: String
            enum CodingKeys: String, CodingKey {
                case id, elementName = "element_name"
            }
        }
        
        let elements: [VisualResult] = try await supabase
            .from("visual_planning")
            .select("id, element_name")
            .order("element_name", ascending: true)
            .execute()
            .value
        
        return elements.map { (id: $0.id.uuidString, name: $0.elementName) }
    }
    
    private func fetchPayments(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct PaymentResult: Decodable {
            let id: Int64
            let paymentDescription: String
            enum CodingKeys: String, CodingKey {
                case id, paymentDescription = "payment_description"
            }
        }
        
        let payments: [PaymentResult] = try await supabase
            .from("payment_plans")
            .select("id, payment_description")
            .order("payment_description", ascending: true)
            .execute()
            .value
        
        return payments.map { (id: String($0.id), name: $0.paymentDescription) }
    }
    
    private func fetchDocuments(supabase: SupabaseClient) async throws -> [(id: String, name: String)] {
        struct DocumentResult: Decodable {
            let id: UUID
            let fileName: String
            enum CodingKeys: String, CodingKey {
                case id, fileName = "file_name"
            }
        }
        
        let documents: [DocumentResult] = try await supabase
            .from("documents")
            .select("id, file_name")
            .order("file_name", ascending: true)
            .execute()
            .value
        
        return documents.map { (id: $0.id.uuidString, name: $0.fileName) }
    }
    
    // MARK: - Markdown Helpers
    
    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        let newText = content + prefix + suffix
        if newText.count <= characterLimit {
            content = newText
        }
    }
    
    // MARK: - Save Logic
    
    private func saveNote() {
        isSaving = true
        
        guard let coupleId = settingsStore.coupleId else {
            logger.warning("No couple ID available - user not authenticated")
            isSaving = false
            return
        }
        
        let noteData = NoteInsertData(
            coupleId: coupleId,
            title: title.isEmpty ? nil : title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            relatedType: selectedType,
            relatedId: selectedEntityId
        )
        
        Task {
            await onSave(noteData)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NoteModalV2(
        note: nil,
        onSave: { _ in },
        onCancel: {}
    )
}
