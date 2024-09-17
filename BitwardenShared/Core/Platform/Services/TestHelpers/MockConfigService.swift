import Combine
import Foundation

@testable import BitwardenShared

class MockConfigService: ConfigService {
    // MARK: Properties

    var configMocker = InvocationMockerWithThrowingResult<(forceRefresh: Bool, isPreAuth: Bool), ServerConfig?>()
    var configSubject = CurrentValueSubject<BitwardenShared.MetaServerConfig?, Never>(nil)
    var featureFlags = [FeatureFlag: AnyCodable]()
    var featureFlagsBool = [FeatureFlag: Bool]()
    var featureFlagsInt = [FeatureFlag: Int]()
    var featureFlagsString = [FeatureFlag: String]()

    // MARK: Methods

    func configPublisher(
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<BitwardenShared.MetaServerConfig?, Never>> {
        configSubject.eraseToAnyPublisher().values
    }

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

    func getRemoteFeatureFlags() async -> [FeatureFlag: AnyCodable] {
        featureFlags
    }
}
