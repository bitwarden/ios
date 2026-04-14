import Networking
import Testing

@testable import BitwardenShared

// MARK: - GetSubscriptionRequestTests

struct GetSubscriptionRequestTests {
    // MARK: Properties

    var subject: GetSubscriptionRequest!

    // MARK: Initialization

    init() {
        subject = GetSubscriptionRequest()
    }

    // MARK: Tests

    /// `method` returns the method of the request.
    @Test
    func method() {
        #expect(subject.method == .get)
    }

    /// `path` returns the path of the request.
    @Test
    func path() {
        #expect(subject.path == "/account/billing/vnext/subscription")
    }
}
