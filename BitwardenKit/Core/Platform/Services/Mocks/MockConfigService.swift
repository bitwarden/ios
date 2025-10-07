import BitwardenKit
import Combine
import Foundation
import TestHelpers

@MainActor
public class MockConfigService: ConfigService {
    // MARK: Properties

    public var configMocker = InvocationMockerWithThrowingResult<(forceRefresh: Bool, isPreAuth: Bool), ServerConfig?>()
    public var configSubject = CurrentValueSubject<MetaServerConfig?, Never>(nil)
    public var debugFeatureFlags = [DebugMenuFeatureFlag]()
    public var featureFlagsBool = [FeatureFlag: Bool]()
    public var featureFlagsBoolPreAuth = [FeatureFlag: Bool]()
    public var featureFlagsInt = [FeatureFlag: Int]()
    public var featureFlagsIntPreAuth = [FeatureFlag: Int]()
    public var featureFlagsString = [FeatureFlag: String]()
    public var featureFlagsStringPreAuth = [FeatureFlag: String]()
    public var getDebugFeatureFlagsCalled = false
    public var refreshDebugFeatureFlagsCalled = false
    public var toggleDebugFeatureFlagCalled = false

    public nonisolated init() {}

    // MARK: Methods

    public func configPublisher(
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<MetaServerConfig?, Never>> {
        configSubject.eraseToAnyPublisher().values
    }

    public func getConfig(forceRefresh: Bool, isPreAuth: Bool) async -> ServerConfig? {
        try? configMocker.invoke(param: (forceRefresh: forceRefresh, isPreAuth: isPreAuth))
    }

    public func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: Bool,
        forceRefresh: Bool,
        isPreAuth: Bool,
    ) async -> Bool {
        let value = isPreAuth ? featureFlagsBoolPreAuth[flag] : featureFlagsBool[flag]
        return value ?? defaultValue
    }

    public func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: Int,
        forceRefresh: Bool,
        isPreAuth: Bool,
    ) async -> Int {
        let value = isPreAuth ? featureFlagsIntPreAuth[flag] : featureFlagsInt[flag]
        return value ?? defaultValue
    }

    public func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: String?,
        forceRefresh: Bool,
        isPreAuth: Bool,
    ) async -> String? {
        let value = isPreAuth ? featureFlagsStringPreAuth[flag] : featureFlagsString[flag]
        return value ?? defaultValue
    }

    public func getDebugFeatureFlags(_ flags: [FeatureFlag]) async -> [DebugMenuFeatureFlag] {
        getDebugFeatureFlagsCalled = true
        return debugFeatureFlags
    }

    public func refreshDebugFeatureFlags(_ flags: [FeatureFlag]) async -> [DebugMenuFeatureFlag] {
        refreshDebugFeatureFlagsCalled = true
        return debugFeatureFlags
    }

    public func toggleDebugFeatureFlag(
        name: String,
        newValue: Bool?,
    ) async {
        toggleDebugFeatureFlagCalled = true
    }
}
