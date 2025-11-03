//
//  TenantContext.swift
//  I Do Blueprint
//
//  Thread-safe tenant context for repositories and background work
//

import Foundation

/// Errors related to tenant context access
enum TenantContextError: LocalizedError {
    case noTenantContext

    var errorDescription: String? {
        switch self {
        case .noTenantContext:
            return "No tenant context available. Please select a wedding to continue."
        }
    }
}

/// Actor providing thread-safe access to the current tenant (couple) ID
actor TenantContextProvider {
    static let shared = TenantContextProvider()

    private var currentTenantId: UUID?

    // MARK: - Accessors
    func getTenantId() -> UUID? {
        currentTenantId
    }

    func requireTenantId() throws -> UUID {
        guard let id = currentTenantId else {
            throw TenantContextError.noTenantContext
        }
        return id
    }

    // MARK: - Mutators
    func setTenantId(_ id: UUID) {
        currentTenantId = id
    }

    func clear() {
        currentTenantId = nil
    }
}
