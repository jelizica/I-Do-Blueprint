import Foundation

public enum ErrorSeverity: String {
    case info       // Informational, no action needed
    case warning    // User should be aware
    case error      // Operation failed, user action may help
    case critical   // Serious issue, may need support
}
