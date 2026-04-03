import Foundation
import Networking

/// An HTTP client that supports client certificate authentication for mTLS.
///
final class CertificateHTTPClient: NSObject, HTTPClient, @unchecked Sendable {
    // MARK: Properties

    /// The certificate service for retrieving client certificates.
    private let certificateService: ClientCertificateService

    /// The underlying URL session.
    private var urlSession: URLSession!

    // MARK: Initialization

    /// Initialize a `CertificateHTTPClient`.
    ///
    /// - Parameter certificateService: The service used to retrieve client certificates.
    ///
    init(certificateService: ClientCertificateService) {
        self.certificateService = certificateService
        super.init()

        // Create a session configuration with a delegate
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil,
        )
    }

    // MARK: HTTPClient

    func download(from urlRequest: URLRequest) async throws -> URL {
        // Use the URLSession extension method
        try await urlSession.download(from: urlRequest)
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        // Use the URLSession extension method
        try await urlSession.send(request)
    }

    // MARK: Private

    /// Handles a `URLAuthenticationChallenge` by providing a client certificate credential when
    /// available, or falling back to default handling.
    ///
    /// - Parameter challenge: The authentication challenge to handle.
    /// - Returns: A tuple containing the disposition and an optional credential. If the challenge
    ///   is not for a client certificate, or no identity is available, returns
    ///   `(.performDefaultHandling, nil)`. Otherwise returns `(.useCredential, credential)`.
    ///
    private func handle(
        _ challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        // Handle client certificate authentication challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            return (.performDefaultHandling, nil)
        }

        guard let identity = await certificateService.getClientCertificateIdentity() else {
            return (.performDefaultHandling, nil)
        }

        // Create the credential with the identity
        let credential = URLCredential(
            identity: identity,
            certificates: nil,
            persistence: .forSession,
        )
        return (.useCredential, credential)
    }
}

// MARK: - URLSessionDelegate & URLSessionTaskDelegate

extension CertificateHTTPClient: URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
    ) async -> URLRequest? {
        // So far we only need 302 redirection to be surfaced and handled manually.
        response.statusCode == 302 ? nil : request
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        await handle(challenge)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        await handle(challenge)
    }
}
