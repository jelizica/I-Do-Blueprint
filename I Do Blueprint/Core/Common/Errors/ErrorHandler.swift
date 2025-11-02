import Foundation
import Combine

@MainActor
public final class ErrorHandler: ObservableObject {
    public static let shared = ErrorHandler()

    @Published public private(set) var currentError: AppError?
    @Published public private(set) var isShowingError = false

    // Using AppLogger general category for error reporting
    private let logger = AppLogger.general

    private init() {}

    public func handle(
        _ error: Error,
        context: ErrorContext,
        source: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let appError = convertToAppError(error, context: context)

        // Log
        logger.error(
            "[\(appError.errorCode)] \(appError.technicalDetails)",
            error: error,
            file: file,
            function: source
        )

        // Report
        if appError.shouldReport {
            SentryService.shared.captureError(error, context: context.dictionary)
        }

        // Publish for UI
        currentError = appError
        isShowingError = true

        Task {
            await ErrorMetrics.shared.recordError(code: appError.errorCode, severity: appError.severity)
        }
    }

    public func dismiss() {
        currentError = nil
        isShowingError = false
    }

    private func convertToAppError(_ error: Error, context: ErrorContext) -> AppError {
        if let appError = error as? AppError { return appError }
        if let urlError = error as? URLError { return NetworkError.from(urlError: urlError) as AppError }
        return GenericError(underlying: error, context: context)
    }
}
