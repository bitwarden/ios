@testable import BitwardenSharedMocks

extension MockCustomHeadersService {
    /// Returns a mock configured to report no custom headers, for tests that exercise the request
    /// pipeline without configuring any.
    ///
    static func withNoHeaders() -> MockCustomHeadersService {
        let service = MockCustomHeadersService()
        service.getCustomHeadersReturnValue = [:]
        return service
    }
}
