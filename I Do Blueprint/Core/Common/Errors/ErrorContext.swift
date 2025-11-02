import Foundation

public struct ErrorContext {
    public let operation: String
    public let feature: String
    public let metadata: [String: Any]

    public init(operation: String, feature: String, metadata: [String: Any] = [:]) {
        self.operation = operation
        self.feature = feature
        self.metadata = metadata
    }

    public var dictionary: [String: Any] {
        var dict = metadata
        dict["operation"] = operation
        dict["feature"] = feature
        return dict
    }
}
