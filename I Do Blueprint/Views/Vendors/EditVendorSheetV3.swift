//
//  EditVendorSheetV3.swift
//  I Do Blueprint
//
//  Refactored modal for editing vendor details with reduced nesting
//  Decomposed into focused components following best practices
//

import SwiftUI
import Supabase
import Storage
import PhotosUI

struct EditVendorSheetV3: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vendorStore: VendorStoreV2
    
    let vendor: Vendor
    let onSave: (Vendor) -> Void
    
    // MARK: - State
    
    @State private var vendorName: String
    @State private var vendorType: String
    @State private var contactName: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var website: String
    @State private var quotedAmount: String
    @State private var isBooked: Bool
    @State private var dateBooked: Date?
    @State private var notes: String
    @State private var isSaving = false
    @State private var selectedImage: NSImage?
    @State private var isUploadingImage = false
    @State private var photosPickerItem: PhotosPickerItem?
    
    // MARK: - Initialization
    
    init(vendor: Vendor, vendorStore: VendorStoreV2, onSave: @escaping (Vendor) -> Void) {
        self.vendor = vendor
        self.vendorStore = vendorStore
        self.onSave = onSave
        _vendorName = State(initialValue: vendor.vendorName)
        _vendorType = State(initialValue: vendor.vendorType ?? "")
        _contactName = State(initialValue: vendor.contactName ?? "")
        _email = State(initialValue: vendor.email ?? "")
        _phoneNumber = State(initialValue: vendor.phoneNumber ?? "")
        _website = State(initialValue: vendor.website ?? "")
        _quotedAmount = State(initialValue: vendor.quotedAmount.map { String(format: "%.0f", $0) } ?? "")
        _isBooked = State(initialValue: vendor.isBooked ?? false)
        _dateBooked = State(initialValue: vendor.dateBooked)
        _notes = State(initialValue: vendor.notes ?? "")
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                EditVendorSheetHeader(
                    vendorName: vendor.vendorName,
                    onDismiss: { dismiss() }
                )
                
                Divider()
                
                formContent
                
                Divider()
                
                EditVendorFooter(
                    isSaving: isSaving,
                    canSave: !vendorName.isEmpty,
                    onCancel: { dismiss() },
                    onSave: { Task { await saveVendor() } }
                )
            }
        }
        .frame(width: 600, height: 700)
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                await loadPhotoFromPicker(newItem)
            }
        }
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xxl) {
                ProfilePictureSection(
                    existingImageUrl: vendor.imageUrl,
                    selectedImage: $selectedImage,
                    photosPickerItem: $photosPickerItem,
                    isUploadingImage: $isUploadingImage
                )
                
                Divider()
                
                BasicInformationSection(
                    vendorName: $vendorName,
                    vendorType: $vendorType
                )
                
                Divider()
                
                ContactInformationSection(
                    contactName: $contactName,
                    email: $email,
                    phoneNumber: $phoneNumber,
                    website: $website
                )
                
                Divider()
                
                BusinessDetailsSection(
                    isBooked: $isBooked,
                    dateBooked: $dateBooked,
                    quotedAmount: $quotedAmount
                )
                
                Divider()
                
                NotesSection(notes: $notes)
            }
            .padding(Spacing.xxl)
        }
    }
    
    // MARK: - Image Handling
    
    private func loadPhotoFromPicker(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let nsImage = NSImage(data: data) {
                    await MainActor.run {
                        selectedImage = nsImage
                    }
                    AppLogger.ui.info("Successfully loaded image from Photos library")
                } else {
                    AppLogger.ui.error("Failed to create NSImage from photo data")
                }
            }
        } catch {
            AppLogger.ui.error("Error loading photo from picker", error: error)
        }
    }
    
    // MARK: - Save Logic
    
    private func saveVendor() async {
        isSaving = true
        defer { isSaving = false }
        
        var updatedVendor = vendor
        
        // Upload image if one was selected
        if let image = selectedImage {
            isUploadingImage = true
            if let imageUrl = await uploadImage(image) {
                updatedVendor.imageUrl = imageUrl
            }
            isUploadingImage = false
        } else if selectedImage == nil && vendor.imageUrl != nil {
            // User removed the image
            updatedVendor.imageUrl = nil
        }
        
        updatedVendor.vendorName = vendorName
        updatedVendor.vendorType = vendorType.isEmpty ? nil : vendorType
        updatedVendor.contactName = contactName.isEmpty ? nil : contactName
        updatedVendor.email = email.isEmpty ? nil : email
        updatedVendor.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        updatedVendor.website = website.isEmpty ? nil : website
        updatedVendor.quotedAmount = Double(quotedAmount)
        updatedVendor.isBooked = isBooked
        updatedVendor.dateBooked = isBooked ? dateBooked : nil
        updatedVendor.notes = notes.isEmpty ? nil : notes
        updatedVendor.updatedAt = Date()
        
        await vendorStore.updateVendor(updatedVendor)
        onSave(updatedVendor)
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
                AppLogger.ui.error("Failed to convert image to PNG data")
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
            
            AppLogger.ui.info("Image uploaded successfully: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            AppLogger.ui.error("Error uploading image", error: error)
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    EditVendorSheetV3(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Sample Vendor",
            vendorType: "Photography",
            vendorCategoryId: nil,
            contactName: "John Doe",
            phoneNumber: "(555) 123-4567",
            email: "john@example.com",
            website: "https://example.com",
            notes: "Sample notes",
            quotedAmount: 3000,
            imageUrl: nil,
            isBooked: false,
            dateBooked: nil,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true
        ),
        vendorStore: VendorStoreV2(),
        onSave: { _ in }
    )
}
