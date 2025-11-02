import XCTest
@testable import I_Do_Blueprint

final class ErrorHandlingTests: XCTestCase {
    func testBudgetError_AppErrorConformance() {
        let err = BudgetError.validationFailed(reason: "amount <= 0")
        XCTAssertEqual(err.errorCode, "BUDGET_VALIDATION_FAILED")
        XCTAssertFalse(err.shouldReport)
        XCTAssertEqual(err.severity, .error)
        XCTAssertTrue(err.userMessage.contains("Invalid"))
        XCTAssertFalse(err.recoveryOptions.isEmpty)
    }

    func testNetworkError_AppErrorConformance() {
        let net = NetworkError.timeout
        XCTAssertEqual(net.errorCode, "NETWORK_TIMEOUT")
        XCTAssertEqual(net.severity, .warning)
        XCTAssertTrue(net.shouldReport)
        XCTAssertFalse(net.recoveryOptions.isEmpty)
    }

    func testErrorHandler_ConvertsURLErrorToNetworkError() async {
        let urlError = URLError(.timedOut)
        let ctx = ErrorContext(operation: "unitTest", feature: "errors")

        let handler = ErrorHandler.shared
        await MainActor.run {
            handler.handle(urlError, context: ctx)
        }
        
        // Verify state was published
        let published = await MainActor.run { handler.currentError }
        XCTAssertNotNil(published)
        XCTAssertEqual(published?.errorCode, "NETWORK_TIMEOUT")
    }
}