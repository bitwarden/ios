import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CipherIconImageLoaderTests

struct CipherIconImageLoaderTests {
    // MARK: Properties

    var certificateService: MockClientCertificateService
    var subject: CipherIconImageLoader

    // MARK: Initialization

    init() {
        certificateService = MockClientCertificateService()
        subject = CipherIconImageLoader()
        subject.configure(certificateService: certificateService)
    }

    // MARK: Tests

    @Test
    func taskDidReceiveChallenge_nonClientCertificate_performsDefaultHandling() async {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        let (disposition, credential) = await subject.urlSession(session, task: task, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

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

    @Test
    func sessionDidReceiveChallenge_nonClientCertificate_performsDefaultHandling() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

        let (disposition, credential) = await subject.urlSession(session, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    @Test
    func sessionDidReceiveChallenge_clientCertificateNoIdentity_performsDefaultHandling() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodClientCertificate)
        certificateService.getClientCertificateIdentityReturnValue = nil

        let (disposition, credential) = await subject.urlSession(session, didReceive: challenge)

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    /// Verifies icon requests participate in mTLS — the loader must query the certificate service
    /// on a client-certificate challenge, not silently skip it.
    @Test
    func sessionDidReceiveChallenge_clientCertificate_queriesCertificateService() async {
        let session = URLSession.shared
        let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodClientCertificate)
        certificateService.getClientCertificateIdentityReturnValue = nil

        _ = await subject.urlSession(session, didReceive: challenge)

        #expect(certificateService.getClientCertificateIdentityCalled)
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
