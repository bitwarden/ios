import Foundation

/// Conforms `URLSession` to the `HTTPClient` protocol.
///
extension URLSession: HTTPClient {
    enum URLDownloadError: Error {
        /// The data was not downloaded to a local url.
        case dataNotDownloaded
    }

    public func download(from urlRequest: URLRequest) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            downloadTask(with: urlRequest) { url, _, error in
                guard let url else {
                    return continuation.resume(with: .failure(error ?? URLDownloadError.dataNotDownloaded))
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

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (field, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: field)
        }

        let (data, urlResponse) = try await data(for: urlRequest)

        return try HTTPResponse(data: data, response: urlResponse, request: request)
    }
}
