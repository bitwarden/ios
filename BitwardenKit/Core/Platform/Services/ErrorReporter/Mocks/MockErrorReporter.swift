@testable import BitwardenKit

public class MockErrorReporter: ErrorReporter {
    public var currentUserId: String?
    public var errors = [Error]()
    public var isEnabled = false
    public var region: (region: String, isPreAuth: Bool)?

    public init() {}

    public func log(error: Error) {
        errors.append(error)
    }

    public func setRegion(_ region: String, isPreAuth: Bool) {
        self.region = (region, isPreAuth)
    }

    public func setUserId(_ userId: String?) {
        currentUserId = userId
    }
}
