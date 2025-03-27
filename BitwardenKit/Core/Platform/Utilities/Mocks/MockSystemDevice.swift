@testable import BitwardenKit

public class MockSystemDevice: SystemDevice {
    public var model = "iPhone"
    public var modelIdentifier = "iPhone14,2"
    public var systemName = "iOS"
    public var systemVersion = "16.4"

    public init(
        model: String = "iPhone",
        modelIdentifier: String = "iPhone14,2",
        systemName: String = "iOS",
        systemVersion: String = "16.4"
    ) {
        self.model = model
        self.modelIdentifier = modelIdentifier
        self.systemName = systemName
        self.systemVersion = systemVersion
    }
}
