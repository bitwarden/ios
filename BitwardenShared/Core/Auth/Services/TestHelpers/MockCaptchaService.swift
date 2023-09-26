import Foundation

@testable import BitwardenShared

class MockCaptchaService: CaptchaService {
    var callbackUrlScheme: String

    var generateCaptchaUrlError: Error?

    init(callbackUrlScheme: String = "callback") {
        self.callbackUrlScheme = callbackUrlScheme
    }

    func generateCaptchaUrl(with siteKey: String) throws -> URL {
        if let generateCaptchaUrlError {
            throw generateCaptchaUrlError
        }

        return .example
    }
}
