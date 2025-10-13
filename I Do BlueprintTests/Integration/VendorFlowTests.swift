//
//  VendorFlowTests.swift
//  I Do BlueprintTests
//
//  Integration tests for complete vendor booking workflows
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class VendorFlowTests: XCTestCase {
    var vendorStore: VendorStoreV2!
    var mockVendorRepository: MockVendorRepository!

    override func setUp() async throws {
        mockVendorRepository = MockVendorRepository()
        vendorStore = withDependencies {
            $0.vendorRepository = mockVendorRepository
        } operation: {
            VendorStoreV2()
        }
    }

    override func tearDown() async throws {
        vendorStore = nil
        mockVendorRepository = nil
    }

    // MARK: - Full Vendor Booking Workflow

    func testFullVendorBookingWorkflow() async throws {
        // Given: Starting with no vendors
        mockVendorRepository.vendors = []
        mockVendorRepository.vendorStats = VendorStats(
            totalVendors: 0,
            bookedVendors: 0,
            pendingVendors: 0,
            totalSpent: 0,
            totalContracted: 0,
            averageRating: 0
        )

        // When: Load initial vendor data
        await vendorStore.loadVendors()

        // Then: Should fetch vendors and stats
        XCTAssertTrue(mockVendorRepository.fetchVendorsCalled, "Should fetch vendors")
        XCTAssertTrue(mockVendorRepository.fetchStatsCalled, "Should fetch stats")
        XCTAssertEqual(vendorStore.vendors.count, 0, "Should have no vendors initially")

        // When: Create new vendor inquiry
        let newVendor = Vendor(
            id: nil,
            name: "Elegant Venues LLC",
            category: "Venue",
            contactName: "Jane Smith",
            email: "jane@elegantvenues.com",
            phone: "555-0123",
            website: "https://elegantvenues.com",
            status: .researching,
            estimatedCost: 15000,
            actualCost: nil,
            depositPaid: nil,
            totalPaid: nil,
            contractSigned: false,
            rating: nil,
            notes: "Beautiful outdoor space",
            createdAt: Date(),
            updatedAt: Date()
        )

        mockVendorRepository.resetFlags()
        await vendorStore.addVendor(newVendor)

        // Then: Vendor should be created
        XCTAssertTrue(mockVendorRepository.createVendorCalled, "Should create vendor")
        XCTAssertEqual(vendorStore.vendors.count, 1, "Should have 1 vendor")
        XCTAssertEqual(vendorStore.vendors.first?.status, .researching, "Status should be researching")

        // When: Update vendor to contacted status
        var contactedVendor = vendorStore.vendors[0]
        contactedVendor.status = .contacted
        contactedVendor.notes = "Sent inquiry email on \(Date())"

        mockVendorRepository.resetFlags()
        await vendorStore.updateVendor(contactedVendor)

        // Then: Vendor status should be updated
        XCTAssertTrue(mockVendorRepository.updateVendorCalled, "Should update vendor")
        XCTAssertEqual(vendorStore.vendors.first?.status, .contacted, "Status should be contacted")

        // When: Book the vendor with contract
        var bookedVendor = vendorStore.vendors[0]
        bookedVendor.status = .booked
        bookedVendor.contractSigned = true
        bookedVendor.actualCost = 14500
        bookedVendor.depositPaid = 5000

        mockVendorRepository.resetFlags()
        await vendorStore.updateVendor(bookedVendor)

        // Then: Vendor should be booked
        XCTAssertTrue(mockVendorRepository.updateVendorCalled, "Should update vendor")
        XCTAssertEqual(vendorStore.vendors.first?.status, .booked, "Status should be booked")
        XCTAssertTrue(vendorStore.vendors.first?.contractSigned ?? false, "Contract should be signed")
        XCTAssertEqual(vendorStore.vendors.first?.depositPaid, 5000, "Deposit should be recorded")

        // When: Complete payment
        var paidVendor = vendorStore.vendors[0]
        paidVendor.totalPaid = 14500

        mockVendorRepository.resetFlags()
        await vendorStore.updateVendor(paidVendor)

        // Then: Payment should be recorded
        XCTAssertTrue(mockVendorRepository.updateVendorCalled, "Should update vendor")
        XCTAssertEqual(vendorStore.vendors.first?.totalPaid, 14500, "Total paid should be recorded")

        // When: Add vendor rating after event
        var ratedVendor = vendorStore.vendors[0]
        ratedVendor.rating = 5

        mockVendorRepository.resetFlags()
        await vendorStore.updateVendor(ratedVendor)

        // Then: Rating should be recorded
        XCTAssertTrue(mockVendorRepository.updateVendorCalled, "Should update vendor")
        XCTAssertEqual(vendorStore.vendors.first?.rating, 5, "Rating should be recorded")

        // Verify final state
        XCTAssertFalse(vendorStore.isLoading, "Should not be loading")
        XCTAssertNil(vendorStore.error, "Should have no errors")
    }

    // MARK: - Multiple Vendor Management Flow

    func testMultipleVendorManagementFlow() async throws {
        // Given: Clean state
        mockVendorRepository.vendors = []

        // When: Add multiple vendors across different categories
        let vendors = [
            Vendor(id: nil, name: "Venue Co", category: "Venue", contactName: "John", email: "john@venue.com", phone: "555-0001", website: nil, status: .researching, estimatedCost: 15000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: nil, createdAt: Date(), updatedAt: Date()),
            Vendor(id: nil, name: "Best Caterers", category: "Catering", contactName: "Mary", email: "mary@caterers.com", phone: "555-0002", website: nil, status: .researching, estimatedCost: 10000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: nil, createdAt: Date(), updatedAt: Date()),
            Vendor(id: nil, name: "Photo Magic", category: "Photography", contactName: "Bob", email: "bob@photo.com", phone: "555-0003", website: nil, status: .researching, estimatedCost: 5000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: nil, createdAt: Date(), updatedAt: Date())
        ]

        for vendor in vendors {
            await vendorStore.addVendor(vendor)
        }

        // Then: All vendors should be added
        XCTAssertEqual(vendorStore.vendors.count, 3, "Should have 3 vendors")

        // When: Update each vendor to different statuses
        var venueVendor = vendorStore.vendors[0]
        venueVendor.status = .booked
        await vendorStore.updateVendor(venueVendor)

        var cateringVendor = vendorStore.vendors[1]
        cateringVendor.status = .contacted
        await vendorStore.updateVendor(cateringVendor)

        var photoVendor = vendorStore.vendors[2]
        photoVendor.status = .rejected
        await vendorStore.updateVendor(photoVendor)

        // Then: Vendors should have different statuses
        XCTAssertEqual(vendorStore.vendors[0].status, .booked)
        XCTAssertEqual(vendorStore.vendors[1].status, .contacted)
        XCTAssertEqual(vendorStore.vendors[2].status, .rejected)

        // When: Delete rejected vendor
        mockVendorRepository.resetFlags()
        await vendorStore.deleteVendor(photoVendor)

        // Then: Vendor should be deleted
        XCTAssertTrue(mockVendorRepository.deleteVendorCalled, "Should delete vendor")
        XCTAssertEqual(vendorStore.vendors.count, 2, "Should have 2 vendors remaining")
        XCTAssertNil(vendorStore.error, "Should have no errors")
    }

    // MARK: - Vendor Update with Rollback Flow

    func testVendorUpdateWithRollback() async throws {
        // Given: Existing vendor
        let existingVendor = Vendor(
            id: 1,
            name: "Venue Co",
            category: "Venue",
            contactName: "John",
            email: "john@venue.com",
            phone: "555-0001",
            website: nil,
            status: .contacted,
            estimatedCost: 15000,
            actualCost: nil,
            depositPaid: nil,
            totalPaid: nil,
            contractSigned: false,
            rating: nil,
            notes: "Initial contact made",
            createdAt: Date(),
            updatedAt: Date()
        )

        mockVendorRepository.vendors = [existingVendor]
        await vendorStore.loadVendors()

        let initialStatus = vendorStore.vendors.first?.status
        let initialNotes = vendorStore.vendors.first?.notes

        // When: Update fails due to error
        mockVendorRepository.shouldThrowError = true
        mockVendorRepository.resetFlags()

        var updatedVendor = existingVendor
        updatedVendor.status = .booked
        updatedVendor.notes = "Attempted to book"

        await vendorStore.updateVendor(updatedVendor)

        // Then: Should rollback to previous state
        XCTAssertTrue(mockVendorRepository.updateVendorCalled, "Should attempt update")
        XCTAssertNotNil(vendorStore.error, "Should have error")
        XCTAssertEqual(vendorStore.vendors.first?.status, initialStatus, "Should rollback status")
        XCTAssertEqual(vendorStore.vendors.first?.notes, initialNotes, "Should rollback notes")
    }

    // MARK: - Vendor Contract and Payment Flow

    func testVendorContractAndPaymentFlow() async throws {
        // Given: Vendor ready for booking
        let vendor = Vendor(
            id: 1,
            name: "Venue Co",
            category: "Venue",
            contactName: "John",
            email: "john@venue.com",
            phone: "555-0001",
            website: nil,
            status: .contacted,
            estimatedCost: 15000,
            actualCost: nil,
            depositPaid: nil,
            totalPaid: nil,
            contractSigned: false,
            rating: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockVendorRepository.vendors = [vendor]
        await vendorStore.loadVendors()

        // When: Sign contract with deposit
        var contractedVendor = vendorStore.vendors[0]
        contractedVendor.contractSigned = true
        contractedVendor.actualCost = 14500
        contractedVendor.depositPaid = 5000
        contractedVendor.status = .booked

        mockVendorRepository.resetFlags()
        await vendorStore.updateVendor(contractedVendor)

        // Then: Contract should be signed
        XCTAssertTrue(vendorStore.vendors.first?.contractSigned ?? false, "Contract should be signed")
        XCTAssertEqual(vendorStore.vendors.first?.depositPaid, 5000, "Deposit should be recorded")
        XCTAssertEqual(vendorStore.vendors.first?.status, .booked, "Status should be booked")

        // When: Make partial payment
        var partialPayment = vendorStore.vendors[0]
        partialPayment.totalPaid = 10000

        mockVendorRepository.resetFlags()
        await vendorStore.updateVendor(partialPayment)

        // Then: Partial payment should be recorded
        XCTAssertEqual(vendorStore.vendors.first?.totalPaid, 10000, "Partial payment recorded")

        // When: Make final payment
        var finalPayment = vendorStore.vendors[0]
        finalPayment.totalPaid = 14500

        mockVendorRepository.resetFlags()
        await vendorStore.updateVendor(finalPayment)

        // Then: Full payment should be recorded
        XCTAssertEqual(vendorStore.vendors.first?.totalPaid, 14500, "Full payment recorded")
        XCTAssertEqual(vendorStore.vendors.first?.totalPaid, vendorStore.vendors.first?.actualCost, "Payment matches actual cost")
        XCTAssertNil(vendorStore.error, "Should have no errors")
    }

    // MARK: - Vendor Comparison Flow

    func testVendorComparisonFlow() async throws {
        // Given: Multiple vendors in same category for comparison
        let vendors = [
            Vendor(id: nil, name: "Venue A", category: "Venue", contactName: "John", email: "a@venue.com", phone: "555-0001", website: nil, status: .researching, estimatedCost: 15000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: "Indoor space", createdAt: Date(), updatedAt: Date()),
            Vendor(id: nil, name: "Venue B", category: "Venue", contactName: "Jane", email: "b@venue.com", phone: "555-0002", website: nil, status: .researching, estimatedCost: 18000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: "Outdoor garden", createdAt: Date(), updatedAt: Date()),
            Vendor(id: nil, name: "Venue C", category: "Venue", contactName: "Bob", email: "c@venue.com", phone: "555-0003", website: nil, status: .researching, estimatedCost: 12000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: "Budget option", createdAt: Date(), updatedAt: Date())
        ]

        for vendor in vendors {
            await vendorStore.addVendor(vendor)
        }

        // When: Update vendors with comparison data
        var venueA = vendorStore.vendors[0]
        venueA.status = .contacted
        venueA.rating = 4
        await vendorStore.updateVendor(venueA)

        var venueB = vendorStore.vendors[1]
        venueB.status = .contacted
        venueB.rating = 5
        await vendorStore.updateVendor(venueB)

        var venueC = vendorStore.vendors[2]
        venueC.status = .contacted
        venueC.rating = 3
        await vendorStore.updateVendor(venueC)

        // Then: All vendors should have comparison data
        XCTAssertEqual(vendorStore.vendors.count, 3, "Should have 3 vendors for comparison")
        XCTAssertEqual(vendorStore.vendors.filter { $0.status == .contacted }.count, 3, "All should be contacted")
        XCTAssertNotNil(vendorStore.vendors[0].rating, "Venue A should have rating")
        XCTAssertNotNil(vendorStore.vendors[1].rating, "Venue B should have rating")
        XCTAssertNotNil(vendorStore.vendors[2].rating, "Venue C should have rating")

        // When: Select best vendor and reject others
        var selectedVendor = vendorStore.vendors[1] // Venue B with highest rating
        selectedVendor.status = .booked
        await vendorStore.updateVendor(selectedVendor)

        var rejectedVendor1 = vendorStore.vendors[0]
        rejectedVendor1.status = .rejected
        await vendorStore.updateVendor(rejectedVendor1)

        var rejectedVendor2 = vendorStore.vendors[2]
        rejectedVendor2.status = .rejected
        await vendorStore.updateVendor(rejectedVendor2)

        // Then: Should have one booked and two rejected
        XCTAssertEqual(vendorStore.vendors.filter { $0.status == .booked }.count, 1, "Should have 1 booked vendor")
        XCTAssertEqual(vendorStore.vendors.filter { $0.status == .rejected }.count, 2, "Should have 2 rejected vendors")
        XCTAssertEqual(vendorStore.vendors.first { $0.status == .booked }?.name, "Venue B", "Venue B should be booked")
        XCTAssertNil(vendorStore.error, "Should have no errors")
    }

    // MARK: - Vendor Refresh Flow

    func testVendorRefreshFlow() async throws {
        // Given: Existing vendors loaded
        let vendor = Vendor(
            id: 1,
            name: "Venue Co",
            category: "Venue",
            contactName: "John",
            email: "john@venue.com",
            phone: "555-0001",
            website: nil,
            status: .contacted,
            estimatedCost: 15000,
            actualCost: nil,
            depositPaid: nil,
            totalPaid: nil,
            contractSigned: false,
            rating: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockVendorRepository.vendors = [vendor]
        await vendorStore.loadVendors()

        XCTAssertEqual(vendorStore.vendors.count, 1, "Should have 1 vendor")

        // When: External update occurs (simulated by updating repository)
        let updatedVendor = Vendor(
            id: 1,
            name: "Venue Co",
            category: "Venue",
            contactName: "John",
            email: "john@venue.com",
            phone: "555-0001",
            website: nil,
            status: .booked,
            estimatedCost: 15000,
            actualCost: 14000,
            depositPaid: 5000,
            totalPaid: nil,
            contractSigned: true,
            rating: nil,
            notes: "Contract signed externally",
            createdAt: Date(),
            updatedAt: Date()
        )

        mockVendorRepository.vendors = [updatedVendor]
        mockVendorRepository.resetFlags()

        // When: Refresh vendors
        await vendorStore.refreshVendors()

        // Then: Should fetch latest data
        XCTAssertTrue(mockVendorRepository.fetchVendorsCalled, "Should fetch vendors on refresh")
        XCTAssertEqual(vendorStore.vendors.first?.status, .booked, "Should have updated status")
        XCTAssertTrue(vendorStore.vendors.first?.contractSigned ?? false, "Should have updated contract status")
        XCTAssertEqual(vendorStore.vendors.first?.actualCost, 14000, "Should have updated actual cost")
        XCTAssertNil(vendorStore.error, "Should have no errors")
    }
}
