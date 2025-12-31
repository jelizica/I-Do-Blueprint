//
//  EditVendorSheetV2.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/8/25.
//  Modal for editing vendor details from vendor list
//

import SwiftUI
import Supabase
import Storage
import UniformTypeIdentifiers
import PhotosUI
import PhoneNumberKit

struct EditVendorSheetV2: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vendorStore: VendorStoreV2

    let vendor: Vendor
    let onSave: (Vendor) -> Void

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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Vendor")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(vendor.vendorName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Form Content
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Profile Picture Section
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Profile Picture", icon: "photo.circle.fill")

                        HStack {
                            Spacer()
                            
                            VStack(spacing: Spacing.md) {
                                // Logo Display
                                ZStack {
                                    Circle()
                                        .fill(AppColors.controlBackground)
                                        .frame(width: 100, height: 100)
                                    
                                    if let image = selectedImage {
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else if let imageUrl = vendor.imageUrl, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                            case .failure, .empty:
                                                Image(systemName: "building.2")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(AppColors.textSecondary)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "building.2")
                                            .font(.system(size: 40))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    if isUploadingImage {
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                            .frame(width: 100, height: 100)
                                        
                                        ProgressView()
                                            .scaleEffect(1.5)
                                            .tint(.white)
                                    }
                                }
                                
                                // Upload/Remove Buttons
                                HStack(spacing: Spacing.sm) {
                                    // Single PhotosPicker button - works for Photos library
                                    PhotosPicker(
                                        selection: $photosPickerItem,
                                        matching: .images,
                                        photoLibrary: .shared()
                                    ) {
                                        Label(selectedImage != nil || vendor.imageUrl != nil ? "Change" : "Upload", systemImage: "photo")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isUploadingImage)
                                    .onChange(of: photosPickerItem) { _, newItem in
                                        Task {
                                            await loadPhotoFromPicker(newItem)
                                        }
                                    }
                                    
                                    if selectedImage != nil || vendor.imageUrl != nil {
                                        Button {
                                            selectedImage = nil
                                            photosPickerItem = nil
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(isUploadingImage)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }

                    Divider()

                    // Basic Information
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Basic Information", icon: "info.circle.fill")

                        VStack(spacing: 16) {
                            FormField(label: "Business Name", required: true) {
                                TextField("Enter business name", text: $vendorName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FormField(label: "Service Type") {
                                TextField("e.g., Photography, Catering", text: $vendorType)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }

                    Divider()

                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Contact Information", icon: "envelope.circle.fill")

                        VStack(spacing: 16) {
                            FormField(label: "Contact Person") {
                                TextField("Contact name", text: $contactName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            FormField(label: "Email") {
                                TextField("contact@example.com", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                            }

                            FormField(label: "Phone") {
                                PhoneNumberTextFieldWrapper(
                                    phoneNumber: $phoneNumber,
                                    defaultRegion: "US",
                                    placeholder: "(555) 123-4567"
                                )
                                .frame(height: 40)
                            }

                            FormField(label: "Website") {
                                TextField("https://example.com", text: $website)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.URL)
                            }
                        }
                    }

                    Divider()

                    // Business Details
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Business Details", icon: "building.2.circle.fill")

                        VStack(spacing: 16) {
                            FormField(label: "Status") {
                                Toggle("Booked", isOn: $isBooked)
                                    .toggleStyle(.switch)
                                    .onChange(of: isBooked) { oldValue, newValue in
                                        // Auto-set date when marking as booked
                                        if newValue && dateBooked == nil {
                                            dateBooked = Date()
                                        }
                                    }
                            }

                            if isBooked {
                                FormField(label: "Booked Date") {
                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: { dateBooked ?? Date() },
                                            set: { dateBooked = $0 }
                                        ),
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(.field)
                                    .labelsHidden()
                                }
                            }

                            FormField(label: "Quoted Amount") {
                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    TextField("0", text: $quotedAmount)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    }

                    Divider()

                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Notes", icon: "note.text")

                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding(Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(Spacing.xxl)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    Task {
                        await saveVendor()
                    }
                } label: {
                    if isSaving {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving...")
                        }
                    } else {
                        Text("Save Changes")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || vendorName.isEmpty)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .frame(width: 600, height: 700)
    }

    /// Load image from PhotosPicker selection
    private func loadPhotoFromPicker(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            // Load the image data from PhotosPicker
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
    
    /// Select image from file system using NSOpenPanel
    private func selectImageFromFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        // Allow all image types
        panel.allowedContentTypes = [.image]
        panel.message = "Select a profile picture for this vendor"
        panel.treatsFilePackagesAsDirectories = false
        panel.canDownloadUbiquitousContents = true
        panel.canResolveUbiquitousConflicts = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Use security-scoped resource access for sandboxed apps
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                if let nsImage = NSImage(contentsOf: url) {
                    selectedImage = nsImage
                    AppLogger.ui.info("Successfully loaded image from file: \(url.lastPathComponent)")
                } else {
                    AppLogger.ui.error("Failed to load image from URL: \(url)")
                }
            }
        }
    }
    
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
            
            // Convert NSImage to PNG data
            guard let tiffData = image.tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffData),
                  let imageData = bitmapImage.representation(using: .png, properties: [:]) else {
                AppLogger.ui.error("Failed to convert image to PNG data")
                return nil
            }
            
            // Generate unique filename
            let fileName = "vendor_\(vendor.id)_\(UUID().uuidString).png"
            
            // Upload to Supabase Storage
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
            
            // Get public URL
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

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppColors.Vendor.contacted)
            Text(title)
                .font(.headline)
        }
    }
}

struct FormField<Content: View>: View {
    let label: String
    var required: Bool = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if required {
                    Text("*")
                        .foregroundColor(.red)
                }
            }

            content
        }
    }
}

#Preview {
    EditVendorSheetV2(
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
