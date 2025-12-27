import XCTest
@testable import I_Do_Blueprint

final class ExpenseApprovalStatusTests: XCTestCase {

    func testExpenseApprovalStatusDefaultsToNil() {
        let expense = Expense.makeTest()
        XCTAssertNil(expense.approvalStatus, "Model builder should default approvalStatus to nil")
    }

    func testExpenseEncodingPreservesNilApprovalStatus() throws {
        let expense = Expense.makeTest()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(expense)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Expense.self, from: data)

        XCTAssertNil(decoded.approvalStatus, "Encoding/decoding should preserve nil approvalStatus")
    }

    func testApprovalStatusCoalescesToPendingForDisplay() {
        let expense = Expense.makeTest()
        // UI coalescing uses (approvalStatus ?? "pending").capitalized
        let display = (expense.approvalStatus ?? "pending").capitalized
        XCTAssertEqual(display, "Pending")
    }
}
