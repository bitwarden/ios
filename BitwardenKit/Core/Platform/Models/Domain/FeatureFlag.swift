public struct FeatureFlag: Codable, Equatable, Hashable, Sendable {
    public let initialValue: AnyCodable?
    public let isRemotelyConfigured: Bool

    public let rawValue: String

    public var name: String {
        rawValue.split(separator: "-").map(\.localizedCapitalized).joined(separator: " ")
    }

    public init(
        rawValue: String,
        initialValue: AnyCodable? = nil,
        isRemotelyConfigured: Bool = true
    ) {
        self.initialValue = initialValue
        self.isRemotelyConfigured = isRemotelyConfigured
        self.rawValue = rawValue
    }

    public var hashValue: Int {
        rawValue.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}
