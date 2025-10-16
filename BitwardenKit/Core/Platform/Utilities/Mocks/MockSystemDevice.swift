@testable import BitwardenKit

public class MockSystemDevice: SystemDevice {
    public var model: String
    public var modelIdentifier: String
    public var systemName: String
    public var systemVersion: String

    public init(
        model: String = "iPhone",
        modelIdentifier: String = "iPhone14,2",
        systemName: String = "iOS",
        systemVersion: String = "16.4",
    ) {
        self.model = model
        self.modelIdentifier = modelIdentifier
        self.systemName = systemName
        self.systemVersion = systemVersion
    }
}
