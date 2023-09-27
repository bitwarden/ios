import Foundation
import Networking

// MARK: - HIBPResponseModel

/// The response returned from the API upon checking the password against data breaches.
///
struct HIBPResponseModel: Response {
    // MARK: Properties

    /// The hash representations of leaked passwords.
    let leakedHashes: [String: Int]

    // MARK: Initialization

    /// Initializes a `HIBPResponseModel`.
    ///
    /// - Parameter response: The data model containing details of the HTTP response that's been received.
    ///
    init(response: HTTPResponse) {
        leakedHashes = String(bytes: response.body, encoding: .utf8)?
            .split(whereSeparator: \.isNewline)
            .reduce(into: [String: Int]()) { result, line in
                let line = String(line)
                guard let colonIndex = line.firstIndex(of: ":") else { return }
                let hash = String(line[..<colonIndex])
                let leakedCount = Int(line[line.index(after: colonIndex)...])
                result[hash] = leakedCount
            } ?? [:]
    }
}
