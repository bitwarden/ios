import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenKit

// MARK: - ConfigResponseModelTests

struct ConfigResponseModelTests {
    /// `ConfigResponseModel` decodes `settings.disableUserRegistration` as `true` when the field
    /// is present in the JSON response.
    @Test
    func decode_disableUserRegistration_true() throws {
        let subject = try JSONDecoder().decode(
            ConfigResponseModel.self,
            from: APITestData.validServerConfigDisableRegistration.data,
        )
        #expect(subject.settings?.disableUserRegistration == true)
    }

    /// `ConfigResponseModel` decodes with `settings` as `nil` when the field is absent from the
    /// JSON response.
    @Test
    func decode_settings_absent() throws {
        let subject = try JSONDecoder().decode(
            ConfigResponseModel.self,
            from: APITestData.validServerConfig.data,
        )
        #expect(subject.settings == nil)
    }
}
