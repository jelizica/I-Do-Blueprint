//
//  InviteCollaboratorSheet.swift
//  I Do Blueprint
//
//  Sheet for inviting new collaborators
//

import SwiftUI

struct InviteCollaboratorSheet: View {
    @ObservedObject var store: CollaborationStoreV2
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var displayName = ""
    @State private var selectedRole: CollaborationRole?
    @State private var isInviting = false

    var isValid: Bool {
        !email.isEmpty && email.contains("@") && selectedRole != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Collaborator Information") {
                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .accessibilityLabel("Email address")

                    TextField("Display Name (Optional)", text: $displayName)
                        .textContentType(.name)
                        .accessibilityLabel("Display name")
                }

                Section("Role") {
                    ForEach(store.roles, id: \.id) { role in
                        RoleSelectionRow(
                            role: role,
                            isSelected: selectedRole?.id == role.id,
                            onSelect: { selectedRole = role }
                        )
                    }
                }

                Section {
                    Button(action: sendInvitation) {
                        if isInviting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Invitation")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isValid || isInviting)
                    .accessibilityLabel("Send invitation")
                    .accessibilityHint(isValid ? "Sends invitation to \(email)" : "Fill in all required fields")
                }
            }
            .navigationTitle("Invite Collaborator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sendInvitation() {
        guard let role = selectedRole else { return }

        isInviting = true

        Task {
            await store.inviteCollaborator(
                email: email,
                roleId: role.id,
                displayName: displayName.isEmpty ? nil : displayName
            )

            isInviting = false

            // Dismiss on success
            if store.error == nil {
                dismiss()
            }
        }
    }
}

// MARK: - Role Selection Row

struct RoleSelectionRow: View {
    let role: CollaborationRole
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.roleName.displayName)
                        .font(.body)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(role.description ?? role.roleName.description)
                        .font(.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Permissions
                    HStack(spacing: 8) {
                        if role.canEdit {
                            PermissionBadge(text: "Edit", color: SemanticColors.statusSuccess)
                        }
                        if role.canDelete {
                            PermissionBadge(text: "Delete", color: SemanticColors.statusWarning)
                        }
                        if role.canInvite {
                            PermissionBadge(text: "Invite", color: SemanticColors.statusInfo)
                        }
                        if role.canManageRoles {
                            PermissionBadge(text: "Manage", color: SemanticColors.primaryAction)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(SemanticColors.primaryAction)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(role.roleName.displayName), \(role.description ?? "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Permission Badge

struct PermissionBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(Opacity.subtle))
            .cornerRadius(4)
    }
}

// MARK: - Previews

#Preview("Invite Collaborator Sheet") {
    InviteCollaboratorSheet(store: CollaborationStoreV2())
}
