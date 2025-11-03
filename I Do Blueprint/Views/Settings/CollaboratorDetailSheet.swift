//
//  CollaboratorDetailSheet.swift
//  I Do Blueprint
//
//  Detail view for managing a collaborator
//

import SwiftUI

struct CollaboratorDetailSheet: View {
    let collaborator: Collaborator
    @ObservedObject var store: CollaborationStoreV2
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var selectedRole: CollaborationRole?

    var body: some View {
        NavigationStack {
            Form {
                // Collaborator Info
                Section("Information") {
                    LabeledContent("Name", value: collaborator.name)
                    LabeledContent("Email", value: collaborator.email)
                    LabeledContent("Status", value: collaborator.status.rawValue.capitalized)

                    if let acceptedAt = collaborator.acceptedAt {
                        LabeledContent("Joined", value: acceptedAt.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                // Role Management
                if store.canManageRoles && collaborator.status == .active {
                    Section("Role") {
                        ForEach(store.roles, id: \.id) { role in
                            RoleSelectionRow(
                                role: role,
                                isSelected: collaborator.roleId == role.id,
                                onSelect: {
                                    selectedRole = role
                                    updateRole(role)
                                }
                            )
                        }
                    }
                }

                // Actions
                if store.canManageRoles {
                    Section {
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Remove Collaborator", systemImage: "person.badge.minus")
                                .frame(maxWidth: .infinity)
                        }
                        .accessibilityLabel("Remove collaborator")
                    }
                }
            }
            .navigationTitle("Collaborator Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Remove Collaborator",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    removeCollaborator()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove \(collaborator.name)? They will lose access to this wedding.")
            }
        }
    }

    private func updateRole(_ role: CollaborationRole) {
        Task {
            await store.updateCollaboratorRole(id: collaborator.id, roleId: role.id)
        }
    }

    private func removeCollaborator() {
        Task {
            await store.removeCollaborator(id: collaborator.id)
            dismiss()
        }
    }
}

// MARK: - Previews

#Preview("Collaborator Detail") {
    CollaboratorDetailSheet(
        collaborator: .makeTest(
            status: .active,
            email: "partner@example.com",
            displayName: "Partner"
        ),
        store: CollaborationStoreV2()
    )
}
