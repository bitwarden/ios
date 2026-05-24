import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherIconImageLoaderTests

struct CipherIconImageLoaderTests {
    // MARK: Properties

    var certificateService: MockClientCertificateService
    var errorReporter: MockErrorReporter
    var subject: CipherIconImageLoader

    // MARK: Initialization

    init() {
        certificateService = MockClientCertificateService()
        errorReporter = MockErrorReporter()
        subject = CipherIconImageLoader()
        subject.configure(certificateService: certificateService, errorReporter: errorReporter)
    }

    // MARK: Tests - urlSession(_:task:didReceive:)

    /// `urlSession(_:task:didReceive:)` returns `.performDefaultHandling` for challenges that are
    /// not for a client certificate.
    @Test
    func taskDidReceiveChallenge_nonClientCertificate_performsDefaultHandling() async {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        let (disposition, credential) = await subject.urlSession(session, task: task, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

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

    // MARK: Tests - urlSession(_:didReceive:)

    /// `urlSession(_:didReceive:)` returns `.performDefaultHandling` for challenges that are not
    /// for a client certificate.
    @Test
    func sessionDidReceiveChallenge_nonClientCertificate_performsDefaultHandling() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        let (disposition, credential) = await subject.urlSession(session, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    /// `urlSession(_:didReceive:)` returns `.performDefaultHandling` when the challenge is for a
    /// client certificate but no identity is available.
    @Test
    func sessionDidReceiveChallenge_clientCertificateNoIdentity_performsDefaultHandling() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodClientCertificate)
        certificateService.getClientCertificateIdentityReturnValue = nil

        let (disposition, credential) = await subject.urlSession(session, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    /// `urlSession(_:didReceive:)` queries the certificate service on a client-certificate
    /// challenge, confirming icon requests participate in mTLS.
    @Test
    func sessionDidReceiveChallenge_clientCertificate_queriesCertificateService() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodClientCertificate)
        certificateService.getClientCertificateIdentityReturnValue = nil

        _ = await subject.urlSession(session, didReceive: challenge)

        #expect(certificateService.getClientCertificateIdentityCalled)
    }

    // MARK: Tests - loadImage(from:)

    /// `loadImage(from:)` returns `nil` when `configure` was never called, so the loader fails
    /// closed instead of falling back to a non-mTLS-aware session.
    @Test
    func loadImage_notConfigured_returnsNil() async {
        let unconfigured = CipherIconImageLoader()

        let image = await unconfigured.loadImage(from: URL(string: "https://example.com/icon.png")!)

        #expect(image == nil)
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
