import Foundation

public enum ErrorRecoveryOption: Hashable {
    case retry
    case cancel
    case contactSupport
    case viewOfflineData
    case tryAgainLater
    case checkConnection
    case custom(title: String)
}

public extension ErrorRecoveryOption {
    var title: String {
        switch self {
        case .retry: return "Retry"
        case .cancel: return "Cancel"
        case .contactSupport: return "Contact Support"
        case .viewOfflineData: return "View Offline Data"
        case .tryAgainLater: return "Try Again Later"
        case .checkConnection: return "Check Connection"
        case .custom(let title): return title
        }
    }
}