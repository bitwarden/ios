@testable import AuthenticatorShared

class MockErrorReporter: ErrorReporter {
    var errors = [Error]()
    var isEnabled = false

    func log(error: Error) {
        errors.append(error)
    }
}
