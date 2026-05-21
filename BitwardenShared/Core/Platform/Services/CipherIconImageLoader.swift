import Foundation
import UIKit

// MARK: - CipherIconImageLoader

/// A singleton that downloads vault item icons through a `URLSession` that participates in mTLS —
/// forwarding client-certificate challenges to `ClientCertificateService` the same way API
/// requests do via `CertificateHTTPClient`.
///
/// Singleton to share a single URLSession across all icon loads and avoid threading the loader
/// through the VaultListItemRow view stack. `configure(certificateService:)` is called once by
/// `ServiceContainer` before any view loads.
///
final class CipherIconImageLoader: NSObject, @unchecked Sendable {
    // MARK: Properties

    static let shared = CipherIconImageLoader()

    private var certificateService: ClientCertificateService?
    private var urlSession: URLSession = .shared

    // MARK: Methods

    func configure(certificateService: ClientCertificateService) {
        self.certificateService = certificateService
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await urlSession.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    // MARK: Private

    private func handle(
        _ challenge: URLAuthenticationChallenge,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodClientCertificate:
            guard let identity = await certificateService?.getClientCertificateIdentity() else {
                return (.performDefaultHandling, nil)
            }
            let credential = URLCredential(identity: identity, certificates: nil, persistence: .forSession)
            return (.useCredential, credential)

        default:
            return (.performDefaultHandling, nil)
        }
    }
}

// MARK: - URLSessionDelegate

extension CipherIconImageLoader: URLSessionDelegate, URLSessionTaskDelegate {
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
