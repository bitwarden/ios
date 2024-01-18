import Foundation

@testable import BitwardenShared

class MockCaptchaService: CaptchaService {
    var callbackUrlSchemeValue: String
    var callbackUrlSchemeGets = 0

    var generateCaptchaSiteKey: String?
    var generateCaptchaUrlResult: Result<URL, Error> = .success(.example)

    var callbackUrlScheme: String {
        callbackUrlSchemeGets += 1
        return callbackUrlSchemeValue
    }

    init(callbackUrlScheme: String = "callback") {
        callbackUrlSchemeValue = callbackUrlScheme
    }

    func generateCaptchaUrl(with siteKey: String) throws -> URL {
        generateCaptchaSiteKey = siteKey
        return try generateCaptchaUrlResult.get()
    }
}
