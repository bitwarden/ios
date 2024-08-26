import Foundation

@testable import AuthenticatorShared

class MockConfigService: ConfigService {
    // MARK: Properties

    var featureFlagsBool = [FeatureFlag: Bool]()
    var featureFlagsInt = [FeatureFlag: Int]()
    var featureFlagsString = [FeatureFlag: String]()

    // MARK: Methods

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
