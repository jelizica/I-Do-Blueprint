//
//  TimelineAPITests.swift
//  I Do BlueprintTests
//
//  Integration tests for TimelineAPI
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class TimelineAPITests: XCTestCase {
    var mockSupabase: MockSupabaseClient!
    var api: TimelineAPI!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSupabase = MockSupabaseClient()
        api = TimelineAPI(supabase: mockSupabase)
    }
    
    override func tearDown() async throws {
        mockSupabase = nil
        api = nil
        try await super.tearDown()
    }
    
    // MARK: - Fetch Timeline Items Tests
    
    func test_fetchTimelineItems_success_aggregatesAllSources() async throws {
        // Given
        let paymentRow = MockSupabaseClient.PaymentRow(
            id: 1,
            couple_id: UUID(),
            expense_id: UUID(),
            payment_date: "2025-01-15",
            amount: 1000.0,
            payment_method: "Credit Card",
            status: "pending",
            notes: "Test payment",
            created_at: "2025-01-01T00:00:00Z",
            updated_at: "2025-01-01T00:00:00Z"
        )
        
        let vendorRow = MockSupabaseClient.VendorRow(
            id: 1,
            couple_id: UUID(),
            vendor_name: "Test Vendor",
            vendor_category: "Catering",
            contact_name: "John Doe",
            contact_email: "john@test.com",
            contact_phone: "555-1234",
            website: nil,
            address: nil,
            notes: nil,
            contract_signed: false,
            contract_date: nil,
            payment_terms: nil,
            created_at: "2025-01-01T00:00:00Z",
            updated_at: "2025-01-01T00:00:00Z"
        )
        
        let guestRow = MockSupabaseClient.GuestRow(
            id: UUID(),
            couple_id: UUID(),
            full_name: "Jane Smith",
            email: "jane@test.com",
            phone: "555-5678",
            rsvp_status: "pending",
            plus_one: false,
            meal_preference: nil,
            dietary_restrictions: nil,
            table_assignment: nil,
            notes: nil,
            created_at: "2025-01-01T00:00:00Z",
            updated_at: "2025-01-01T00:00:00Z"
        )
        
        mockSupabase.mockPayments = [paymentRow]
        mockSupabase.mockVendors = [vendorRow]
        mockSupabase.mockGuests = [guestRow]
        
        // When
        let items = try await api.fetchTimelineItems()
        
        // Then
        XCTAssertEqual(items.count, 3, "Should aggregate all timeline items")
        XCTAssertTrue(items.contains { $0.title.contains("Payment") })
        XCTAssertTrue(items.contains { $0.title.contains("Vendor") })
        XCTAssertTrue(items.contains { $0.title.contains("Guest") })
    }
    
    func test_fetchTimelineItems_emptyData_returnsEmptyArray() async throws {
        // Given
        mockSupabase.mockPayments = []
        mockSupabase.mockVendors = []
        mockSupabase.mockGuests = []
        
        // When
        let items = try await api.fetchTimelineItems()
        
        // Then
        XCTAssertTrue(items.isEmpty, "Should return empty array when no data")
    }
    
    func test_fetchTimelineItems_sortsByDate() async throws {
        // Given
        let payment1 = MockSupabaseClient.PaymentRow(
            id: 1,
            couple_id: UUID(),
            expense_id: UUID(),
            payment_date: "2025-01-20",
            amount: 1000.0,
            payment_method: "Credit Card",
            status: "pending",
            notes: nil,
            created_at: "2025-01-01T00:00:00Z",
            updated_at: "2025-01-01T00:00:00Z"
        )
        
        let payment2 = MockSupabaseClient.PaymentRow(
            id: 2,
            couple_id: UUID(),
            expense_id: UUID(),
            payment_date: "2025-01-10",
            amount: 500.0,
            payment_method: "Cash",
            status: "paid",
            notes: nil,
            created_at: "2025-01-01T00:00:00Z",
            updated_at: "2025-01-01T00:00:00Z"
        )
        
        mockSupabase.mockPayments = [payment1, payment2]
        mockSupabase.mockVendors = []
        mockSupabase.mockGuests = []
        
        // When
        let items = try await api.fetchTimelineItems()
        
        // Then
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items[0].itemDate < items[1].itemDate, "Items should be sorted by date ascending")
    }
    
    func test_fetchTimelineItems_networkError_throwsError() async {
        // Given
        mockSupabase.shouldThrowError = true
        mockSupabase.errorToThrow = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When/Then
        do {
            _ = try await api.fetchTimelineItems()
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error, "Should throw network error")
        }
    }
    
    // MARK: - Timeline Item CRUD Tests
    
    func test_fetchTimelineItemById_success() async throws {
        // Given
        let itemId = UUID()
        let mockItem = TimelineItem(
            id: itemId,
            coupleId: UUID(),
            title: "Test Item",
            description: "Test description",
            itemDate: Date(),
            itemType: .custom,
            completed: false,
            relatedEntityType: nil,
            relatedEntityId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockTimelineItem = mockItem
        
        // When
        let item = try await api.fetchTimelineItemById(itemId)
        
        // Then
        XCTAssertEqual(item.id, itemId)
        XCTAssertEqual(item.title, "Test Item")
    }
    
    func test_createTimelineItem_success() async throws {
        // Given
        let insertData = TimelineItemInsertData(
            coupleId: UUID(),
            title: "New Item",
            description: "New description",
            itemDate: Date(),
            itemType: .custom,
            completed: false,
            relatedEntityType: nil,
            relatedEntityId: nil
        )
        
        let mockItem = TimelineItem(
            id: UUID(),
            coupleId: insertData.coupleId,
            title: insertData.title,
            description: insertData.description,
            itemDate: insertData.itemDate,
            itemType: insertData.itemType,
            completed: insertData.completed,
            relatedEntityType: insertData.relatedEntityType,
            relatedEntityId: insertData.relatedEntityId,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockTimelineItem = mockItem
        
        // When
        let item = try await api.createTimelineItem(insertData)
        
        // Then
        XCTAssertEqual(item.title, "New Item")
        XCTAssertEqual(item.description, "New description")
    }
    
    func test_updateTimelineItem_success() async throws {
        // Given
        let itemId = UUID()
        let updateData = TimelineItemInsertData(
            coupleId: UUID(),
            title: "Updated Item",
            description: "Updated description",
            itemDate: Date(),
            itemType: .custom,
            completed: false,
            relatedEntityType: nil,
            relatedEntityId: nil
        )
        
        let mockItem = TimelineItem(
            id: itemId,
            coupleId: updateData.coupleId,
            title: updateData.title,
            description: updateData.description,
            itemDate: updateData.itemDate,
            itemType: updateData.itemType,
            completed: updateData.completed,
            relatedEntityType: updateData.relatedEntityType,
            relatedEntityId: updateData.relatedEntityId,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockTimelineItem = mockItem
        
        // When
        let item = try await api.updateTimelineItem(itemId, data: updateData)
        
        // Then
        XCTAssertEqual(item.id, itemId)
        XCTAssertEqual(item.title, "Updated Item")
    }
    
    func test_updateTimelineItemCompletion_success() async throws {
        // Given
        let itemId = UUID()
        let mockItem = TimelineItem(
            id: itemId,
            coupleId: UUID(),
            title: "Test Item",
            description: "Test",
            itemDate: Date(),
            itemType: .custom,
            completed: true,
            relatedEntityType: nil,
            relatedEntityId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockTimelineItem = mockItem
        
        // When
        let item = try await api.updateTimelineItemCompletion(itemId, completed: true)
        
        // Then
        XCTAssertTrue(item.completed)
    }
    
    func test_deleteTimelineItem_success() async throws {
        // Given
        let itemId = UUID()
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.deleteTimelineItem(itemId)
        // Should not throw
    }
    
    // MARK: - Milestone CRUD Tests
    
    func test_fetchMilestones_success() async throws {
        // Given
        let milestone1 = Milestone(
            id: UUID(),
            coupleId: UUID(),
            title: "Milestone 1",
            description: "Description 1",
            targetDate: Date(),
            completed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        let milestone2 = Milestone(
            id: UUID(),
            coupleId: UUID(),
            title: "Milestone 2",
            description: "Description 2",
            targetDate: Date(),
            completed: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockMilestones = [milestone1, milestone2]
        
        // When
        let milestones = try await api.fetchMilestones()
        
        // Then
        XCTAssertEqual(milestones.count, 2)
        XCTAssertEqual(milestones[0].title, "Milestone 1")
        XCTAssertEqual(milestones[1].title, "Milestone 2")
    }
    
    func test_fetchMilestoneById_success() async throws {
        // Given
        let milestoneId = UUID()
        let mockMilestone = Milestone(
            id: milestoneId,
            coupleId: UUID(),
            title: "Test Milestone",
            description: "Test description",
            targetDate: Date(),
            completed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockMilestone = mockMilestone
        
        // When
        let milestone = try await api.fetchMilestoneById(milestoneId)
        
        // Then
        XCTAssertEqual(milestone.id, milestoneId)
        XCTAssertEqual(milestone.title, "Test Milestone")
    }
    
    func test_createMilestone_success() async throws {
        // Given
        let insertData = MilestoneInsertData(
            coupleId: UUID(),
            title: "New Milestone",
            description: "New description",
            targetDate: Date(),
            completed: false
        )
        
        let mockMilestone = Milestone(
            id: UUID(),
            coupleId: insertData.coupleId,
            title: insertData.title,
            description: insertData.description,
            targetDate: insertData.targetDate,
            completed: insertData.completed,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockMilestone = mockMilestone
        
        // When
        let milestone = try await api.createMilestone(insertData)
        
        // Then
        XCTAssertEqual(milestone.title, "New Milestone")
    }
    
    func test_updateMilestone_success() async throws {
        // Given
        let milestoneId = UUID()
        let updateData = MilestoneInsertData(
            coupleId: UUID(),
            title: "Updated Milestone",
            description: "Updated description",
            targetDate: Date(),
            completed: false
        )
        
        let mockMilestone = Milestone(
            id: milestoneId,
            coupleId: updateData.coupleId,
            title: updateData.title,
            description: updateData.description,
            targetDate: updateData.targetDate,
            completed: updateData.completed,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockMilestone = mockMilestone
        
        // When
        let milestone = try await api.updateMilestone(milestoneId, data: updateData)
        
        // Then
        XCTAssertEqual(milestone.id, milestoneId)
        XCTAssertEqual(milestone.title, "Updated Milestone")
    }
    
    func test_updateMilestoneCompletion_success() async throws {
        // Given
        let milestoneId = UUID()
        let mockMilestone = Milestone(
            id: milestoneId,
            coupleId: UUID(),
            title: "Test Milestone",
            description: "Test",
            targetDate: Date(),
            completed: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockSupabase.mockMilestone = mockMilestone
        
        // When
        let milestone = try await api.updateMilestoneCompletion(milestoneId, completed: true)
        
        // Then
        XCTAssertTrue(milestone.completed)
    }
    
    func test_deleteMilestone_success() async throws {
        // Given
        let milestoneId = UUID()
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.deleteMilestone(milestoneId)
        // Should not throw
    }
}

// MARK: - Mock Supabase Client

class MockSupabaseClient {
    var shouldThrowError = false
    var errorToThrow: Error?
    var deleteSucceeds = true
    
    // Mock data
    var mockPayments: [PaymentRow] = []
    var mockVendors: [VendorRow] = []
    var mockGuests: [GuestRow] = []
    var mockTimelineItem: TimelineItem?
    var mockMilestones: [Milestone] = []
    var mockMilestone: Milestone?
    
    // Mock row structures
    struct PaymentRow: Codable {
        let id: Int64
        let couple_id: UUID
        let expense_id: UUID
        let payment_date: String
        let amount: Double
        let payment_method: String
        let status: String
        let notes: String?
        let created_at: String
        let updated_at: String
    }
    
    struct VendorRow: Codable {
        let id: Int
        let couple_id: UUID
        let vendor_name: String
        let vendor_category: String
        let contact_name: String?
        let contact_email: String?
        let contact_phone: String?
        let website: String?
        let address: String?
        let notes: String?
        let contract_signed: Bool
        let contract_date: String?
        let payment_terms: String?
        let created_at: String
        let updated_at: String
    }
    
    struct GuestRow: Codable {
        let id: UUID
        let couple_id: UUID
        let full_name: String
        let email: String?
        let phone: String?
        let rsvp_status: String
        let plus_one: Bool
        let meal_preference: String?
        let dietary_restrictions: String?
        let table_assignment: String?
        let notes: String?
        let created_at: String
        let updated_at: String
    }
}
