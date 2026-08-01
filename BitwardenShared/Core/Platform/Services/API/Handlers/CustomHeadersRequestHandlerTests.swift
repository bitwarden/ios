import BitwardenKitMocks
import Foundation
import Networking
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

struct CustomHeadersRequestHandlerTests {
    // MARK: Properties

    var customHeadersService: MockCustomHeadersService
    var environmentService: MockEnvironmentService
    var subject: CustomHeadersRequestHandler

    // MARK: Initialization

    init() {
        customHeadersService = MockCustomHeadersService()
        environmentService = MockEnvironmentService()
        subject = CustomHeadersRequestHandler(
            customHeadersService: customHeadersService,
            environmentService: environmentService,
        )
    }

    // MARK: Tests

    /// `handle(_:)` applies the custom headers to a request sent to an environment host.
    @Test
    func handle_environmentHost_addsCustomHeaders() async throws {
        customHeadersService.getCustomHeadersReturnValue = [
            "CF-Access-Client-Id": "client-id",
            "CF-Access-Client-Secret": "client-secret",
        ]
        var request = HTTPRequest(url: URL(string: "https://example.com/api/sync")!)

        let handledRequest = try await subject.handle(&request)

        #expect(handledRequest.headers["CF-Access-Client-Id"] == "client-id")
        #expect(handledRequest.headers["CF-Access-Client-Secret"] == "client-secret")
    }

    /// `handle(_:)` leaves existing request headers in place when adding custom headers.
    @Test
    func handle_environmentHost_preservesOtherHeaders() async throws {
        customHeadersService.getCustomHeadersReturnValue = ["Custom-Header": "value"]
        var request = HTTPRequest(
            url: URL(string: "https://example.com/api/sync")!,
            headers: ["Bitwarden-Client-Name": "mobile"],
        )

        let handledRequest = try await subject.handle(&request)

        #expect(handledRequest.headers["Bitwarden-Client-Name"] == "mobile")
        #expect(handledRequest.headers["Custom-Header"] == "value")
    }

    /// `handle(_:)` does not apply custom headers to a request sent to a third-party host.
    @Test
    func handle_nonEnvironmentHost_doesNotAddCustomHeaders() async throws {
        customHeadersService.getCustomHeadersReturnValue = ["CF-Access-Client-Secret": "client-secret"]
        var request = HTTPRequest(url: URL(string: "https://api.pwnedpasswords.com/range/12345")!)

        let handledRequest = try await subject.handle(&request)

        #expect(handledRequest.headers["CF-Access-Client-Secret"] == nil)
    }

    /// `handle(_:)` leaves the request unchanged when no custom headers are configured.
    @Test
    func handle_noCustomHeaders_doesNotModifyRequest() async throws {
        customHeadersService.getCustomHeadersReturnValue = [:]
        var request = HTTPRequest(url: URL(string: "https://example.com/api/sync")!)

        let handledRequest = try await subject.handle(&request)

        #expect(handledRequest.headers.isEmpty)
    }
}
