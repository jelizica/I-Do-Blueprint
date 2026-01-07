//
//  EditVendorSheetV4.swift
//  I Do Blueprint
//
//  V4 Edit Vendor Modal with tabbed interface
//  Features: Overview (edit), Financial (view), Documents (view), Notes (edit)
//  Theme-aware implementation using existing design system
//

import SwiftUI
import Supabase
import Storage
import PhotosUI
import Dependencies

// MARK: - Tab Enum

enum EditVendorTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case financial = "Financial"
    case documents = "Documents"
    case notes = "Notes"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .financial: return "dollarsign.circle"
        case .documents: return "doc.text"
        case .notes: return "note.text"
        }
    }
    
    var isEditable: Bool {
        switch self {
        case .overview, .notes: return true
        case .financial, .documents: return false
        }
    }
}

// MARK: - Main View

struct EditVendorSheetV4: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Dependencies
    
    @Dependency(\.budgetRepository) private var budgetRepository
    @Dependency(\.documentRepository) private var documentRepository
    
    // MARK: - Properties
    
    @ObservedObject var vendorStore: VendorStoreV2
    let vendor: Vendor
    let onSave: (Vendor) -> Void
    
    // MARK: - State - Tab Selection
    
    @State private var selectedTab: EditVendorTab = .overview
    
    // MARK: - State - Overview Fields
    
    @State private var vendorName: String
    @State private var vendorType: String
    @State private var priorityLevel: VendorPriority = .medium
    @State private var contactEmail: String
    @State private var phoneNumber: String
    @State private var website: String
    @State private var streetAddress: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var country: String
    @State private var instagramHandle: String
    @State private var isBooked: Bool
    @State private var dateBooked: Date
    @State private var includeInExport: Bool
    @State private var isArchived: Bool
    @State private var quickNote: String
    
    // MARK: - State - Category Selection
    
    @State private var budgetCategoryId: UUID?
    @State private var subcategoryId: UUID?
    
    // MARK: - Budget Store for Categories
    
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    
    // MARK: - App Coordinator for Window Size
    
    @EnvironmentObject private var coordinator: AppCoordinator
    
    // MARK: - State - Image
    
    @State private var selectedImage: NSImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    
    // MARK: - State - Financial Data
    
    @State private var expenses: [Expense] = []
    @State private var payments: [PaymentSchedule] = []
    @State private var isLoadingFinancials = false
    
    // MARK: - State - Documents Data
    
    @State private var documents: [Document] = []
    @State private var isLoadingDocuments = false
    
    // MARK: - State - Notes
    
    @State private var vendorNotes: [VendorNote] = []
    @State private var newNoteText: String = ""
    @State private var notesSearchText: String = ""
    
    // MARK: - State - UI
    
    @State private var isSaving = false
    @State private var showDeleteAlert = false
    
    // MARK: - Logger
    
    private let logger = AppLogger.ui
    
    // MARK: - Size Constants (Proportional Modal Sizing Pattern)
    
    /// Minimum modal width
    private let minWidth: CGFloat = 400
    /// Maximum modal width
    private let maxWidth: CGFloat = 700
    /// Minimum modal height
    private let minHeight: CGFloat = 350
    /// Maximum modal height
    private let maxHeight: CGFloat = 850
    /// Buffer for window chrome (title bar, toolbar)
    private let windowChromeBuffer: CGFloat = 40
    /// Width proportion of parent window
    private let widthProportion: CGFloat = 0.60
    /// Height proportion of parent window
    private let heightProportion: CGFloat = 0.75
    
    // MARK: - Computed Properties
    
    /// Calculate dynamic size based on parent window size
    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        
        // Calculate proportional size
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion - windowChromeBuffer
        
        // Clamp to min/max bounds
        let finalWidth = min(maxWidth, max(minWidth, targetWidth))
        let finalHeight = min(maxHeight, max(minHeight, targetHeight))
        
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
    // MARK: - Initialization
    
    init(vendor: Vendor, vendorStore: VendorStoreV2, onSave: @escaping (Vendor) -> Void) {
        self.vendor = vendor
        self.vendorStore = vendorStore
        self.onSave = onSave
        
        // Initialize state from vendor
        _vendorName = State(initialValue: vendor.vendorName)
        _vendorType = State(initialValue: vendor.vendorType ?? "")
        _contactEmail = State(initialValue: vendor.email ?? "")
        _phoneNumber = State(initialValue: vendor.phoneNumber ?? "")
        _website = State(initialValue: vendor.website ?? "")
        _streetAddress = State(initialValue: vendor.streetAddress ?? "")
        _city = State(initialValue: vendor.city ?? "")
        _state = State(initialValue: vendor.state ?? "")
        _zipCode = State(initialValue: vendor.postalCode ?? "")
        _country = State(initialValue: vendor.country ?? "USA")
        _instagramHandle = State(initialValue: vendor.instagramHandle ?? "")
        _isBooked = State(initialValue: vendor.isBooked ?? false)
        _dateBooked = State(initialValue: vendor.dateBooked ?? Date())
        _includeInExport = State(initialValue: vendor.includeInExport ?? true)
        _isArchived = State(initialValue: vendor.isArchived ?? false)
        _quickNote = State(initialValue: vendor.notes ?? "")
        
        // Initialize category from vendor
        _budgetCategoryId = State(initialValue: vendor.budgetCategoryId)
        _subcategoryId = State(initialValue: nil) // Subcategory is derived from budgetCategoryId
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Tab Bar
            tabBar
            
            // Content
            contentSection
            
            // Footer (only for editable tabs)
            if selectedTab.isEditable {
                footerSection
            }
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
        .macOSShadow(.modal)
        .task {
            await loadAllData()
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                await loadPhotoFromPicker(newItem)
            }
        }
        .alert("Delete Vendor", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await deleteVendor() }
            }
        } message: {
            Text("Are you sure you want to delete \(vendorName)? This action cannot be undone.")
        }
    }
    
    // MARK: - Glass Background
    
    private var glassBackground: some View {
        ZStack {
            // Base background
            SemanticColors.backgroundPrimary
            
            // Glass effect overlay
            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.85)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: Spacing.lg) {
            // Vendor Avatar/Logo
            vendorAvatarSection
            
            // Vendor Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(vendorName.isEmpty ? "New Vendor" : vendorName)
                    .font(Typography.title2)
                    .foregroundColor(SemanticColors.textPrimary)
                
                HStack(spacing: Spacing.sm) {
                    // Category Badge
                    if !vendorType.isEmpty {
                        Text(vendorType)
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(SemanticColors.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }
                    
                    // Booked Status Badge
                    if isBooked {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Booked")
                        }
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.Vendor.booked)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(AppColors.Vendor.booked.opacity(Opacity.subtle))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                    }
                }
            }
            
            Spacer()
            
            // Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(SemanticColors.backgroundSecondary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.lg)
        .background(
            SemanticColors.backgroundPrimary.opacity(0.4)
        )
    }
    
    // MARK: - Vendor Avatar Section
    
    private var vendorAvatarSection: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            Group {
                if let image = selectedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let imageUrl = vendor.imageUrl,
                          let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            vendorInitialsView
                        @unknown default:
                            vendorInitialsView
                        }
                    }
                } else {
                    vendorInitialsView
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )
            .macOSShadow(.subtle)
            
            // Edit Button
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Image(systemName: "pencil")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(SemanticColors.backgroundPrimary)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(SemanticColors.borderLight, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: 4)
        }
    }
    
    private var vendorInitialsView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BlushPink.shade100,
                    SemanticColors.backgroundPrimary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Text(vendorInitials)
                .font(Typography.title3)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }
    
    private var vendorInitials: String {
        let words = vendorName.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "V"
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(EditVendorTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.md)
        .background(
            SemanticColors.backgroundPrimary.opacity(0.2)
        )
    }
    
    private func tabButton(for tab: EditVendorTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                
                Text(tab.rawValue)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                
                // Document count badge
                if tab == .documents && !documents.isEmpty {
                    Text("\(documents.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(SemanticColors.primaryAction)
                        .clipShape(Circle())
                }
            }
            .foregroundColor(selectedTab == tab ? SemanticColors.primaryAction : SemanticColors.textSecondary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                Group {
                    if selectedTab == tab {
                        SemanticColors.primaryActionLight
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                }
            )
            .overlay(
                Group {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.primaryAction.opacity(0.3), lineWidth: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        ScrollView {
            Group {
                switch selectedTab {
                case .overview:
                    EditVendorOverviewTabV4(
                        vendorName: $vendorName,
                        vendorType: $vendorType,
                        priorityLevel: $priorityLevel,
                        contactEmail: $contactEmail,
                        phoneNumber: $phoneNumber,
                        website: $website,
                        streetAddress: $streetAddress,
                        city: $city,
                        state: $state,
                        zipCode: $zipCode,
                        country: $country,
                        instagramHandle: $instagramHandle,
                        isBooked: $isBooked,
                        dateBooked: $dateBooked,
                        includeInExport: $includeInExport,
                        isArchived: $isArchived,
                        quickNote: $quickNote,
                        budgetCategoryId: $budgetCategoryId,
                        subcategoryId: $subcategoryId,
                        budgetCategories: budgetStore.categoryStore.categories
                    )
                    
                case .financial:
                    EditVendorFinancialTabV4(
                        vendor: vendor,
                        expenses: expenses,
                        payments: payments,
                        isLoading: isLoadingFinancials
                    )
                    
                case .documents:
                    EditVendorDocumentsTabV4(
                        documents: documents,
                        isLoading: isLoadingDocuments
                    )
                    
                case .notes:
                    EditVendorNotesTabV4(
                        notes: $vendorNotes,
                        newNoteText: $newNoteText,
                        searchText: $notesSearchText,
                        onSaveNote: saveNote
                    )
                }
            }
            .padding(Spacing.xxl)
        }
        .background(SemanticColors.backgroundSecondary.opacity(0.3))
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack {
            // Delete Button
            Button {
                showDeleteAlert = true
            } label: {
                Text("Delete Vendor")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.statusError)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Cancel Button
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(SemanticColors.backgroundPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            
            // Save Button
            Button {
                Task { await saveVendor() }
            } label: {
                HStack(spacing: Spacing.xs) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                    }
                    Text("Save Changes")
                        .font(Typography.bodySmall)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(SemanticColors.primaryAction)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .macOSShadow(.subtle)
            }
            .buttonStyle(.plain)
            .disabled(vendorName.isEmpty || isSaving)
            .opacity(vendorName.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.lg)
        .background(
            SemanticColors.backgroundPrimary.opacity(0.4)
        )
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadFinancialData() }
            group.addTask { await loadDocuments() }
            group.addTask { await loadNotes() }
        }
    }
    
    private func loadFinancialData() async {
        await MainActor.run { isLoadingFinancials = true }
        
        do {
            async let expensesTask = budgetRepository.fetchExpensesByVendor(vendorId: vendor.id)
            async let paymentsTask = budgetRepository.fetchPaymentSchedulesByVendor(vendorId: vendor.id)
            
            let fetchedExpenses = try await expensesTask
            let fetchedPayments = try await paymentsTask
            
            await MainActor.run {
                expenses = fetchedExpenses
                payments = fetchedPayments
                isLoadingFinancials = false
            }
            
            logger.info("Loaded financial data: \(fetchedExpenses.count) expenses, \(fetchedPayments.count) payments")
        } catch {
            logger.error("Error loading financial data", error: error)
            await MainActor.run { isLoadingFinancials = false }
        }
    }
    
    private func loadDocuments() async {
        await MainActor.run { isLoadingDocuments = true }
        
        do {
            let fetchedDocuments = try await documentRepository.fetchDocuments(vendorId: Int(vendor.id))
            
            await MainActor.run {
                documents = fetchedDocuments
                isLoadingDocuments = false
            }
            
            logger.info("Loaded \(fetchedDocuments.count) documents")
        } catch {
            logger.error("Error loading documents", error: error)
            await MainActor.run { isLoadingDocuments = false }
        }
    }
    
    private func loadNotes() async {
        // Parse existing notes from vendor.notes field
        // In a real implementation, this would fetch from a notes table
        if let notesText = vendor.notes, !notesText.isEmpty {
            let note = VendorNote(
                id: UUID(),
                content: notesText,
                authorType: .system,
                createdAt: vendor.updatedAt ?? Date()
            )
            await MainActor.run {
                vendorNotes = [note]
            }
        }
    }
    
    // MARK: - Image Handling
    
    private func loadPhotoFromPicker(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let nsImage = NSImage(data: data) {
                await MainActor.run {
                    selectedImage = nsImage
                }
                logger.info("Successfully loaded image from Photos library")
            }
        } catch {
            logger.error("Error loading photo from picker", error: error)
        }
    }
    
    // MARK: - Save Logic
    
    private func saveVendor() async {
        await MainActor.run { isSaving = true }
        defer { Task { @MainActor in isSaving = false } }
        
        var updatedVendor = vendor
        
        // Upload image if selected
        if let image = selectedImage {
            if let imageUrl = await uploadImage(image) {
                updatedVendor.imageUrl = imageUrl
            }
        }
        
        // Update all fields
        updatedVendor.vendorName = vendorName
        updatedVendor.vendorType = vendorType.isEmpty ? nil : vendorType
        updatedVendor.email = contactEmail.isEmpty ? nil : contactEmail
        updatedVendor.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        updatedVendor.website = website.isEmpty ? nil : website
        updatedVendor.streetAddress = streetAddress.isEmpty ? nil : streetAddress
        updatedVendor.city = city.isEmpty ? nil : city
        updatedVendor.state = state.isEmpty ? nil : state
        updatedVendor.postalCode = zipCode.isEmpty ? nil : zipCode
        updatedVendor.country = country.isEmpty ? nil : country
        updatedVendor.instagramHandle = instagramHandle.isEmpty ? nil : instagramHandle
        updatedVendor.isBooked = isBooked
        updatedVendor.dateBooked = isBooked ? dateBooked : nil
        updatedVendor.includeInExport = includeInExport
        updatedVendor.isArchived = isArchived
        updatedVendor.archivedAt = isArchived ? Date() : nil
        updatedVendor.notes = quickNote.isEmpty ? nil : quickNote
        updatedVendor.updatedAt = Date()
        
        // Update budget category - use subcategory if selected, otherwise use parent category
        updatedVendor.budgetCategoryId = subcategoryId ?? budgetCategoryId
        
        await vendorStore.updateVendor(updatedVendor)
        onSave(updatedVendor)
        
        logger.info("Vendor saved: \(updatedVendor.vendorName)")
        dismiss()
    }
    
    private func uploadImage(_ image: NSImage) async -> String? {
        do {
            guard let supabase = SupabaseManager.shared.client else {
                throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
            }
            
            guard let tiffData = image.tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffData),
                  let imageData = bitmapImage.representation(using: .png, properties: [:]) else {
                logger.error("Failed to convert image to PNG data")
                return nil
            }
            
            let fileName = "vendor_\(vendor.id)_\(UUID().uuidString).png"
            
            try await NetworkRetry.withRetry {
                try await supabase.storage
                    .from("vendor-profile-pics")
                    .upload(
                        path: fileName,
                        file: imageData,
                        options: FileOptions(
                            cacheControl: "3600",
                            contentType: "image/png",
                            upsert: true
                        )
                    )
            }
            
            let publicURL = try supabase.storage
                .from("vendor-profile-pics")
                .getPublicURL(path: fileName)
            
            logger.info("Image uploaded: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            logger.error("Error uploading image", error: error)
            return nil
        }
    }
    
    private func deleteVendor() async {
        await vendorStore.deleteVendor(vendor)
        logger.info("Vendor deleted: \(vendor.vendorName)")
        dismiss()
    }
    
    private func saveNote() {
        guard !newNoteText.isEmpty else { return }
        
        let newNote = VendorNote(
            id: UUID(),
            content: newNoteText,
            authorType: .partner1,
            createdAt: Date()
        )
        
        vendorNotes.insert(newNote, at: 0)
        newNoteText = ""
        
        // Update the quick note field as well
        quickNote = vendorNotes.map { $0.content }.joined(separator: "\n\n")
        
        logger.info("Note saved for vendor")
    }
}

// MARK: - Supporting Types

enum VendorPriority: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var color: Color {
        switch self {
        case .high: return SemanticColors.statusError
        case .medium: return SemanticColors.primaryAction
        case .low: return SemanticColors.textSecondary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .high: return SemanticColors.statusErrorLight
        case .medium: return SemanticColors.primaryActionLight
        case .low: return SemanticColors.backgroundSecondary
        }
    }
}

struct VendorNote: Identifiable {
    let id: UUID
    let content: String
    let authorType: NoteAuthorType
    let createdAt: Date
    
    enum NoteAuthorType {
        case partner1
        case partner2
        case system
        
        var displayName: String {
            switch self {
            case .partner1: return "Partner 1"
            case .partner2: return "Partner 2"
            case .system: return "System"
            }
        }
        
        var color: Color {
            switch self {
            case .partner1, .partner2: return SemanticColors.primaryAction
            case .system: return SemanticColors.textSecondary
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .partner1, .partner2: return SemanticColors.primaryAction.opacity(Opacity.subtle)
            case .system: return SemanticColors.backgroundSecondary
            }
        }
    }
}

// MARK: - Preview

#Preview("Edit Vendor V4") {
    EditVendorSheetV4(
        vendor: .makeTest(),
        vendorStore: VendorStoreV2(),
        onSave: { _ in }
    )
}
