import BitwardenKit
import Foundation
import UIKit

// MARK: - CipherIconImageLoader

/// A singleton that downloads vault item icons through a `URLSession` that participates in mTLS —
/// forwarding client-certificate challenges to `ClientCertificateService` the same way API
/// requests do via `CertificateHTTPClient`.
///
/// Singleton to share a single URLSession across all icon loads and avoid threading the loader
/// through the VaultListItemRow view stack. `configure(certificateService:customHeadersService:errorReporter:)`
/// is called once by `ServiceContainer` before any view loads.
///
final class CipherIconImageLoader: NSObject, @unchecked Sendable {
    // MARK: Properties

    /// The shared instance configured by `ServiceContainer` at app/extension startup.
    static let shared = CipherIconImageLoader()

    /// The service used to resolve the user's client certificate identity for mTLS challenges.
    private var certificateService: ClientCertificateService?

    /// The service used to get the user's custom headers for icon requests. Icon URLs always come
    /// from the environment's icons URL, so the headers apply to every icon request.
    private var customHeadersService: CustomHeadersService?

    /// The service used to report non-fatal errors, including misconfiguration of this loader.
    private var errorReporter: ErrorReporter?

    /// The session used to download icons. Defaults to `URLSession.shared` until `configure` is
    /// called, at which point it is replaced with a session whose delegate is `self`.
    private var urlSession: URLSession = .shared

    // MARK: Methods

    /// Configures the loader with the services needed to participate in mTLS, apply custom
    /// headers, and report errors. Must be called once at startup before any icon loads.
    ///
    /// - Parameters:
    ///   - certificateService: The service used to resolve the user's client certificate.
    ///   - customHeadersService: The service used to get the user's custom headers.
    ///   - errorReporter: The service used to report non-fatal errors.
    ///
    func configure(
        certificateService: ClientCertificateService,
        customHeadersService: CustomHeadersService,
        errorReporter: ErrorReporter,
    ) {
        self.certificateService = certificateService
        self.customHeadersService = customHeadersService
        self.errorReporter = errorReporter
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    /// Builds the request used to download the icon at the given URL, attaching the user's custom
    /// headers. Icon URLs always come from the environment's icons URL, so the headers apply to
    /// every icon request.
    ///
    /// - Parameter url: The icon URL.
    /// - Returns: The request used to download the icon.
    ///
    func iconRequest(for url: URL) async -> URLRequest {
        var request = URLRequest(url: url)
        if let customHeadersService {
            for (name, value) in await customHeadersService.getCustomHeaders() {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }
        return request
    }

    /// Downloads and decodes the icon at the given URL.
    ///
    /// - Parameter url: The icon URL.
    /// - Returns: The decoded image, or `nil` if the loader is not configured, the request failed,
    ///   or the response was non-2xx. Callers should fall back to a placeholder on `nil`.
    ///
    func loadImage(from url: URL) async -> UIImage? {
        guard certificateService != nil else {
            errorReporter?.log(error: BitwardenError.generalError(
                type: "CipherIconImageLoader",
                message: "`configure(certificateService:customHeadersService:errorReporter:)` "
                    + "must be called before loading icons.",
            ))
            return nil
        }
        do {
            let request = await iconRequest(for: url)
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    // MARK: Private

    /// Handles a `URLAuthenticationChallenge` by providing the user's client certificate when
    /// available, or deferring to default handling for other challenge types.
    ///
    /// - Parameter challenge: The authentication challenge to handle.
    /// - Returns: A disposition and optional credential to apply to the challenge.
    ///
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
