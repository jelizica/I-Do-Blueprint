import Foundation
import Sentry

public final class ErrorMetrics {
    public static let shared = ErrorMetrics()
    private init() {}

    public func recordError(code: String, severity: ErrorSeverity) async {
        let message = "AppError captured: \(code) [severity=\(severity.rawValue)]"
        AppLogger.analytics.info(message)
        SentryService.shared.addBreadcrumb(
            message: message,
            category: "error",
            level: severity.sentryLevel,
            data: ["error_code": code, "severity": severity.rawValue]
        )
    }
}

private extension ErrorSeverity {
    var sentryLevel: SentryLevel {
        switch self {
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .critical: return .fatal
        }
    }
}
