import Foundation

public enum ErrorSeverity: String {
    case info = "info"         // Informational, no action needed
    case warning = "warning"   // User should be aware
    case error = "error"       // Operation failed, user action may help
    case critical = "critical" // Serious issue, may need support
}
