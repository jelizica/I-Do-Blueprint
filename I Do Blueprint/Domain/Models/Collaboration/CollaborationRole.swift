//
//  CollaborationRole.swift
//  I Do Blueprint
//
//  Collaboration role definitions with permissions
//

import Foundation

/// Represents a collaboration role with permissions
struct CollaborationRole: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let roleName: RoleName
    let description: String?
    let canEdit: Bool
    let canDelete: Bool
    let canInvite: Bool
    let canManageRoles: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case roleName = "role_name"
        case description = "description"
        case canEdit = "can_edit"
        case canDelete = "can_delete"
        case canInvite = "can_invite"
        case canManageRoles = "can_manage_roles"
    }
}

/// Predefined collaboration roles
enum RoleName: String, Codable, Sendable, CaseIterable {
    case owner = "owner"
    case partner = "partner"
    case planner = "planner"
    case viewer = "viewer"

    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .partner: return "Partner"
        case .planner: return "Wedding Planner"
        case .viewer: return "Viewer"
        }
    }

    var description: String {
        switch self {
        case .owner:
            return "Full access to all features and settings"
        case .partner:
            return "Full editing access, can invite others"
        case .planner:
            return "Can edit and manage wedding details"
        case .viewer:
            return "Read-only access to wedding details"
        }
    }

    /// Default permissions for each role
    var permissions: RolePermissions {
        switch self {
        case .owner:
            return RolePermissions(canEdit: true, canDelete: true, canInvite: true, canManageRoles: true)
        case .partner:
            return RolePermissions(canEdit: true, canDelete: true, canInvite: true, canManageRoles: false)
        case .planner:
            return RolePermissions(canEdit: true, canDelete: false, canInvite: false, canManageRoles: false)
        case .viewer:
            return RolePermissions(canEdit: false, canDelete: false, canInvite: false, canManageRoles: false)
        }
    }
}

struct RolePermissions: Codable, Sendable, Hashable {
    let canEdit: Bool
    let canDelete: Bool
    let canInvite: Bool
    let canManageRoles: Bool
}


// MARK: - Test Helpers

extension CollaborationRole {
    /// Creates a test role with default values
    static func makeTest(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        roleName: RoleName = .partner,
        description: String? = nil,
        canEdit: Bool? = nil,
        canDelete: Bool? = nil,
        canInvite: Bool? = nil,
        canManageRoles: Bool? = nil
    ) -> CollaborationRole {
        let permissions = roleName.permissions
        return CollaborationRole(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            roleName: roleName,
            description: description ?? roleName.description,
            canEdit: canEdit ?? permissions.canEdit,
            canDelete: canDelete ?? permissions.canDelete,
            canInvite: canInvite ?? permissions.canInvite,
            canManageRoles: canManageRoles ?? permissions.canManageRoles
        )
    }
}
