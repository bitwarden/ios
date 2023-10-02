import Foundation

@testable import BitwardenShared

class MockCaptchaService: CaptchaService {
    var callbackUrlSchemeValue: String
    var callbackUrlSchemeGets = 0

    var generateCaptchaUrlValue: URL = .example
    var generateCaptchaUrlError: Error?
    var generateCaptchaSiteKey: String?

    var callbackUrlScheme: String {
        callbackUrlSchemeGets += 1
        return callbackUrlSchemeValue
    }

    init(callbackUrlScheme: String = "callback") {
        callbackUrlSchemeValue = callbackUrlScheme
    }

    func generateCaptchaUrl(with siteKey: String) throws -> URL {
        generateCaptchaSiteKey = siteKey

        if let generateCaptchaUrlError {
            throw generateCaptchaUrlError
        }

        return generateCaptchaUrlValue
    }
}
