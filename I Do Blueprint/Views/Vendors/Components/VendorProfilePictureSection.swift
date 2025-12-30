//
//  VendorProfilePictureSection.swift
//  I Do Blueprint
//
//  Component for vendor profile picture upload and display
//

import SwiftUI
import PhotosUI

struct VendorProfilePictureSection: View {
    let vendor: Vendor
    @Binding var selectedImage: NSImage?
    @Binding var photosPickerItem: PhotosPickerItem?
    let isUploadingImage: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Profile Picture", icon: "photo.circle.fill")
            
            HStack {
                Spacer()
                
                VStack(spacing: Spacing.md) {
                    // Logo Display
                    logoDisplay
                    
                    // Upload/Remove Buttons
                    actionButtons
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var logoDisplay: some View {
        ZStack {
            Circle()
                .fill(AppColors.controlBackground)
                .frame(width: 100, height: 100)
            
            imageContent
            
            if isUploadingImage {
                uploadingOverlay
            }
        }
    }
    
    @ViewBuilder
    private var imageContent: some View {
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
                    placeholderIcon
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            placeholderIcon
        }
    }
    
    private var placeholderIcon: some View {
        Image(systemName: "building.2")
            .font(.system(size: 40))
            .foregroundColor(AppColors.textSecondary)
    }
    
    private var uploadingOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 100, height: 100)
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            PhotosPicker(
                selection: $photosPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    selectedImage != nil || vendor.imageUrl != nil ? "Change" : "Upload",
                    systemImage: "photo"
                )
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .disabled(isUploadingImage)
            
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
}

#Preview {
    VendorProfilePictureSection(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Sample Vendor",
            vendorType: "Photography",
            vendorCategoryId: nil,
            contactName: nil,
            phoneNumber: nil,
            email: nil,
            website: nil,
            notes: nil,
            quotedAmount: nil,
            imageUrl: nil,
            isBooked: false,
            dateBooked: nil,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true
        ),
        selectedImage: .constant(nil),
        photosPickerItem: .constant(nil),
        isUploadingImage: false
    )
    .padding()
}
