//
//  MockRepositories.swift
//  I Do BlueprintTests
//
//  Backward-compatible re-export of all mock repositories
//  This file maintains compatibility with existing tests while the mocks
//  are now organized in separate files under MockRepositories/
//
//  Migration Note: Tests can now import individual mocks directly from
//  the MockRepositories/ directory for better organization and faster compilation.
//

import Foundation
import Dependencies
@testable import I_Do_Blueprint

// MARK: - Re-exports for Backward Compatibility

// All mock repository classes are now defined in separate files:
// - MockRepositories/MockGuestRepository.swift
// - MockRepositories/MockBudgetRepository.swift
// - MockRepositories/MockTaskRepository.swift
// - MockRepositories/MockTimelineRepository.swift
// - MockRepositories/MockSettingsRepository.swift
// - MockRepositories/MockNotesRepository.swift
// - MockRepositories/MockDocumentRepository.swift
// - MockRepositories/MockVendorRepository.swift
// - MockRepositories/MockVisualPlanningRepository.swift
// - MockRepositories/MockCollaborationRepository.swift
// - MockRepositories/MockPresenceRepository.swift
// - MockRepositories/MockActivityFeedRepository.swift

// This file now serves as a convenience import point for tests that
// previously imported from the monolithic MockRepositories.swift file.
// New tests should import individual mocks directly for better clarity.
