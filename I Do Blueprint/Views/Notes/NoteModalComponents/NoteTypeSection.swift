//
//  NoteTypeSection.swift
//  I Do Blueprint
//
//  Component for note type and entity selection
//

import SwiftUI

struct NoteTypeSection: View {
    @Binding var selectedType: NoteRelatedType?
    @Binding var selectedEntityId: String?
    @Binding var availableEntities: [(id: String, name: String)]
    @Binding var isLoadingEntities: Bool
    let onTypeChange: (NoteRelatedType?) async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Related To")
                .font(.headline)
                .fontWeight(.semibold)
            
            typePicker
            
            if selectedType != nil {
                entitySelector
            }
        }
    }
    
    // MARK: - Subviews
    
    private var typePicker: some View {
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
                .fill(AppColors.controlBackground)
        )
        .onChange(of: selectedType) { oldType, newType in
            if oldType != newType {
                selectedEntityId = nil
                availableEntities = []
                if newType != nil {
                    Task {
                        await onTypeChange(newType)
                    }
                }
            }
        }
    }
    
    private var entitySelector: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Link to Specific Item")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if isLoadingEntities {
                loadingView
            } else if availableEntities.isEmpty {
                emptyStateView
            } else {
                entityPicker
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.7)
            Text("Loading...")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.controlBackground)
        )
    }
    
    private var emptyStateView: some View {
        Text("No \(selectedType?.displayName.lowercased() ?? "items") available")
            .font(.caption)
            .foregroundColor(AppColors.textSecondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.controlBackground)
            )
    }
    
    private var entityPicker: some View {
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
                .fill(AppColors.controlBackground)
        )
    }
}

#Preview {
    NoteTypeSection(
        selectedType: .constant(.vendor),
        selectedEntityId: .constant(nil),
        availableEntities: .constant([
            (id: "1", name: "Sample Vendor"),
            (id: "2", name: "Another Vendor")
        ]),
        isLoadingEntities: .constant(false),
        onTypeChange: { _ in }
    )
    .padding()
}
