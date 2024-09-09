import Combine
import Foundation

@testable import BitwardenShared

class MockConfigService: ConfigService {
    // MARK: Properties

    var config: ServerConfig?
    var configSubject = CurrentValueSubject<BitwardenShared.MetaServerConfig?, Never>(nil)
    var featureFlagsBool = [FeatureFlag: Bool]()
    var featureFlagsInt = [FeatureFlag: Int]()
    var featureFlagsString = [FeatureFlag: String]()

    // MARK: Methods

    func configPublisher(
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<BitwardenShared.MetaServerConfig?, Never>> {
        configSubject.eraseToAnyPublisher().values
    }

    func getConfig(forceRefresh: Bool, isPreAuth: Bool) async -> ServerConfig? {
        config
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
}
