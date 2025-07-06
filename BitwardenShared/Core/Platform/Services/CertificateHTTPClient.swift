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
            delegateQueue: nil
        )
    }

    // MARK: HTTPClient

    func download(from urlRequest: URLRequest) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            urlSession.downloadTask(with: urlRequest) { url, _, error in
                guard let url else {
                    return continuation.resume(with: .failure(error ?? URLError(.badURL)))
                }

                do {
                    let temporaryURL = try FileManager.default.url(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true
                    )
                    .appendingPathComponent("temp")
                    .appendingPathComponent(url.lastPathComponent)

                    try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true)

                    // Remove any existing document at file
                    if FileManager.default.fileExists(atPath: temporaryURL.path) {
                        try FileManager.default.removeItem(at: temporaryURL)
                    }

                    // Copy the newly downloaded file to the temporary url.
                    try FileManager.default.copyItem(
                        at: url,
                        to: temporaryURL
                    )

                    continuation.resume(with: .success(temporaryURL))
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }.resume()
        }
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (field, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: field)
        }

        let (data, urlResponse) = try await urlSession.data(for: urlRequest)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard let responseURL = httpResponse.url else {
            throw URLError(.badURL)
        }

        return HTTPResponse(
            url: responseURL,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
            body: data,
            requestID: request.requestID
        )
    }
}

// MARK: - URLSessionDelegate

extension CertificateHTTPClient: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Handle client certificate authentication challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        Task {
            guard let certificateInfo = await certificateService.getClientCertificateForTLS() else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            // Try to create the identity directly using Keychain Services
            var importResult: CFArray?
            let importOptions: [String: Any] = [
                kSecImportExportPassphrase as String: certificateInfo.password,
            ]

            let status = SecPKCS12Import(
                certificateInfo.data as CFData,
                importOptions as CFDictionary,
                &importResult
            )

            guard status == errSecSuccess,
                  let importArray = importResult as? [[String: Any]],
                  !importArray.isEmpty else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            // Get the first import result
            let firstImport = importArray[0]

            // Extract the identity using the Security framework constant
            guard let identityAny = firstImport[kSecImportItemIdentity as String] else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            // Use Unmanaged to safely bridge the CoreFoundation type
            let identityRef = Unmanaged<SecIdentity>.fromOpaque(
                UnsafeRawPointer(Unmanaged.passUnretained(identityAny as AnyObject).toOpaque())
            ).takeUnretainedValue()

            // Create the credential with the identity
            let credential = URLCredential(
                identity: identityRef,
                certificates: nil,
                persistence: .forSession
            )
            completionHandler(.useCredential, credential)
        }
    }
}
