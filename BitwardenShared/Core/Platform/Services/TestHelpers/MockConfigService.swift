import BitwardenKit
import Combine
import Foundation
import TestHelpers

@testable import BitwardenShared

@MainActor
class MockConfigService: ConfigService {
    // MARK: Properties

    var configMocker = InvocationMockerWithThrowingResult<(forceRefresh: Bool, isPreAuth: Bool), ServerConfig?>()
    var configSubject = CurrentValueSubject<BitwardenShared.MetaServerConfig?, Never>(nil)
    var debugFeatureFlags = [DebugMenuFeatureFlag]()
    var featureFlagsBool = [FeatureFlag: Bool]()
    var featureFlagsBoolPreAuth = [FeatureFlag: Bool]()
    var featureFlagsInt = [FeatureFlag: Int]()
    var featureFlagsIntPreAuth = [FeatureFlag: Int]()
    var featureFlagsString = [FeatureFlag: String]()
    var featureFlagsStringPreAuth = [FeatureFlag: String]()
    var getDebugFeatureFlagsCalled = false
    var refreshDebugFeatureFlagsCalled = false
    var toggleDebugFeatureFlagCalled = false

    nonisolated init() {}

    // MARK: Methods

    func configPublisher(
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<BitwardenShared.MetaServerConfig?, Never>> {
        configSubject.eraseToAnyPublisher().values
    }

    func getConfig(forceRefresh: Bool, isPreAuth: Bool) async -> ServerConfig? {
        try? configMocker.invoke(param: (forceRefresh: forceRefresh, isPreAuth: isPreAuth))
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool, forceRefresh: Bool, isPreAuth: Bool) async -> Bool {
        let value = isPreAuth ? featureFlagsBoolPreAuth[flag] : featureFlagsBool[flag]
        return value ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int, forceRefresh: Bool, isPreAuth: Bool) async -> Int {
        let value = isPreAuth ? featureFlagsIntPreAuth[flag] : featureFlagsInt[flag]
        return value ?? defaultValue
    }

    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: String?,
        forceRefresh: Bool,
        isPreAuth: Bool
    ) async -> String? {
        let value = isPreAuth ? featureFlagsStringPreAuth[flag] : featureFlagsString[flag]
        return value ?? defaultValue
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
