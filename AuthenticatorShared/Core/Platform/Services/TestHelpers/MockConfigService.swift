import Combine
import Foundation

@testable import AuthenticatorShared

@MainActor
class MockConfigService: ConfigService {
    // MARK: Properties

    var configMocker = InvocationMockerWithThrowingResult<(forceRefresh: Bool, isPreAuth: Bool), ServerConfig?>()
    var debugFeatureFlags = [DebugMenuFeatureFlag]()
    var featureFlagsBool = [FeatureFlag: Bool]()
    var featureFlagsInt = [FeatureFlag: Int]()
    var featureFlagsString = [FeatureFlag: String]()
    var getDebugFeatureFlagsCalled = false
    var refreshDebugFeatureFlagsCalled = false
    var toggleDebugFeatureFlagCalled = false

    nonisolated init() {}

    // MARK: Methods

    func getConfig(forceRefresh: Bool, isPreAuth: Bool) async -> ServerConfig? {
        try? configMocker.invoke(param: (forceRefresh: forceRefresh, isPreAuth: isPreAuth))
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool, forceRefresh: Bool, isPreAuth: Bool) async -> Bool {
        featureFlagsBool[flag] ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int, forceRefresh: Bool, isPreAuth: Bool) async -> Int {
        featureFlagsInt[flag] ?? defaultValue
    }

    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: String?,
        forceRefresh: Bool,
        isPreAuth: Bool
    ) async -> String? {
        featureFlagsString[flag] ?? defaultValue
    }

    func getDebugFeatureFlags() async -> [DebugMenuFeatureFlag] {
        getDebugFeatureFlagsCalled = true
        return debugFeatureFlags
    }

    func refreshDebugFeatureFlags() async -> [DebugMenuFeatureFlag] {
        refreshDebugFeatureFlagsCalled = true
        return debugFeatureFlags
    }

    func toggleDebugFeatureFlag(
        name: String,
        newValue: Bool?
    ) async -> [DebugMenuFeatureFlag] {
        toggleDebugFeatureFlagCalled = true
        return debugFeatureFlags
    }
}
