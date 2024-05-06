import Foundation

@testable import BitwardenShared

class MockConfigService: ConfigService {
    // MARK: Properties

    var config: ServerConfig?
    var featureFlagsBool = [FeatureFlag: Bool]()
    var featureFlagsInt = [FeatureFlag: Int]()
    var featureFlagsString = [FeatureFlag: String]()

    // MARK: Methods

    func getConfig(forceRefresh: Bool) async -> ServerConfig? {
        config
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool, forceRefresh: Bool) async -> Bool {
        featureFlagsBool[flag] ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int, forceRefresh: Bool) async -> Int {
        featureFlagsInt[flag] ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String?, forceRefresh: Bool) async -> String? {
        featureFlagsString[flag] ?? defaultValue
    }
}
