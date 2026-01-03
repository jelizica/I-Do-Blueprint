//
//  ProfilePictureSection.swift
//  I Do Blueprint
//
//  Component for vendor profile picture upload and display
//

import SwiftUI
import PhotosUI

struct ProfilePictureSection: View {
    let existingImageUrl: String?
    @Binding var selectedImage: NSImage?
    @Binding var photosPickerItem: PhotosPickerItem?
    @Binding var isUploadingImage: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VendorSectionHeader(title: "Profile Picture", icon: "photo.circle.fill")
            
            HStack {
                Spacer()
                
                VStack(spacing: Spacing.md) {
                    profileImageDisplay
                    uploadControls
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var profileImageDisplay: some View {
        ZStack {
            Circle()
                .fill(SemanticColors.backgroundSecondary)
                .frame(width: 100, height: 100)
            
            imageContent
            
            if isUploadingImage {
                uploadingOverlay
            }
        }
        .accessibilityLabel("Vendor profile picture")
    }
    
    @ViewBuilder
    private var imageContent: some View {
        if let image = selectedImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
        } else if let imageUrl = existingImageUrl, let url = URL(string: imageUrl) {
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
    
    private var uploadControls: some View {
        HStack(spacing: Spacing.sm) {
            PhotosPicker(
                selection: $photosPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    selectedImage != nil || existingImageUrl != nil ? "Change" : "Upload",
                    systemImage: "photo"
                )
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .disabled(isUploadingImage)
            
            if selectedImage != nil || existingImageUrl != nil {
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
    
    private var placeholderIcon: some View {
        Image(systemName: "building.2")
            .font(.system(size: 40))
            .foregroundColor(SemanticColors.textSecondary)
    }
}

#Preview {
    ProfilePictureSection(
        existingImageUrl: nil,
        selectedImage: .constant(nil),
        photosPickerItem: .constant(nil),
        isUploadingImage: .constant(false)
    )
    .padding()
}
