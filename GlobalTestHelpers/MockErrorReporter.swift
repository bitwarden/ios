@testable import BitwardenShared

class MockErrorReporter: ErrorReporter {
    var currentUserId: String?
    var errors = [Error]()
    var isEnabled = false
    var region: (region: String, isPreAuth: Bool)?

    func log(error: Error) {
        errors.append(error)
    }

    func setRegion(_ region: String, isPreAuth: Bool) {
        self.region = (region, isPreAuth)
    }

    func setUserId(_ userId: String?) {
        currentUserId = userId
    }
}
