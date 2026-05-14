import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CertificateHTTPClientTests

struct CertificateHTTPClientTests {
    // MARK: Properties

    var certificateService: MockClientCertificateService
    var subject: CertificateHTTPClient

    // MARK: Initialization

    init() {
        certificateService = MockClientCertificateService()
        subject = CertificateHTTPClient(certificateService: certificateService)
    }

    // MARK: Tests - Redirect handling

    /// `urlSession(_:task:willPerformHTTPRedirection:newRequest:)` returns `nil` for 302
    /// responses, preventing automatic redirect.
    @Test
    func willPerformHTTPRedirection_302_blocksRedirect() async {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 302,
            httpVersion: nil,
            headerFields: nil,
        )!
        let newRequest = URLRequest(url: URL(string: "https://redirected.example.com")!)

        let result = await subject.urlSession(
            session,
            task: task,
            willPerformHTTPRedirection: response,
            newRequest: newRequest,
        )

        #expect(result == nil)
    }

    /// `urlSession(_:task:willPerformHTTPRedirection:newRequest:)` returns the new request for
    /// 301 responses, allowing automatic redirect.
    @Test
    func willPerformHTTPRedirection_301_allowsRedirect() async {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 301,
            httpVersion: nil,
            headerFields: nil,
        )!
        let newRequest = URLRequest(url: URL(string: "https://redirected.example.com")!)

        let result = await subject.urlSession(
            session,
            task: task,
            willPerformHTTPRedirection: response,
            newRequest: newRequest,
        )

        #expect(result == newRequest)
    }

    /// `urlSession(_:task:willPerformHTTPRedirection:newRequest:)` returns the new request for
    /// 303 responses, allowing automatic redirect.
    @Test
    func willPerformHTTPRedirection_303_allowsRedirect() async {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 303,
            httpVersion: nil,
            headerFields: nil,
        )!
        let newRequest = URLRequest(url: URL(string: "https://redirected.example.com")!)

        let result = await subject.urlSession(
            session,
            task: task,
            willPerformHTTPRedirection: response,
            newRequest: newRequest,
        )

        #expect(result == newRequest)
    }

    // MARK: Tests - Auth challenge handling

    /// `urlSession(_:task:didReceive:)` returns `.performDefaultHandling` when the challenge is
    /// for a client certificate but no identity is available.
    @Test
    func taskDidReceiveChallenge_clientCertificateNoIdentity_performsDefaultHandling() async {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodClientCertificate)
        certificateService.getClientCertificateIdentityReturnValue = nil

        let (disposition, credential) = await subject.urlSession(session, task: task, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    /// `urlSession(_:task:didReceive:)` returns `.performDefaultHandling` for non-client-certificate
    /// challenges.
    @Test
    func taskDidReceiveChallenge_nonClientCertificate_performsDefaultHandling() async {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        let (disposition, credential) = await subject.urlSession(session, task: task, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    /// `urlSession(_:didReceive:)` returns `.performDefaultHandling` when the challenge is
    /// for a client certificate but no identity is available.
    @Test
    func sessionDidReceiveChallenge_clientCertificateNoIdentity_performsDefaultHandling() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodClientCertificate)
        certificateService.getClientCertificateIdentityReturnValue = nil

        let (disposition, credential) = await subject.urlSession(session, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    /// `urlSession(_:didReceive:)` returns `.performDefaultHandling` for non-client-certificate
    /// challenges.
    @Test
    func sessionDidReceiveChallenge_nonClientCertificate_performsDefaultHandling() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        let (disposition, credential) = await subject.urlSession(session, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    // MARK: Private

    private func makeChallenge(authenticationMethod: String) -> URLAuthenticationChallenge {
        let protectionSpace = URLProtectionSpace(
            host: "example.com",
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: authenticationMethod,
        )
        return URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: MockAuthenticationChallengeSender(),
        )
    }
}

// MARK: - MockAuthenticationChallengeSender

private class MockAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}
