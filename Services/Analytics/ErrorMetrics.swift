import Foundation

public final class ErrorMetrics {
    public static let shared = ErrorMetrics()
    private init() {}

    public func recordError(code: String, severity: ErrorSeverity) async {
        // Placeholder for analytics integration; intentionally no-op for now
        // Hook into existing AnalyticsService if desired in later phases
    }
}