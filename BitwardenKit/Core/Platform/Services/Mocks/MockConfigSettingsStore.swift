import BitwardenKit

public class MockConfigSettingsStore: ConfigSettingsStore {
    public var featureFlags = [String: Bool]()
    public var overrideDebugFeatureFlagCalled = false

    public init() {}

    public func debugFeatureFlag(name: String) -> Bool? {
        featureFlags[name]
    }

    public func overrideDebugFeatureFlag(name: String, value: Bool?) {
        overrideDebugFeatureFlagCalled = true
        featureFlags[name] = value
    }
}
