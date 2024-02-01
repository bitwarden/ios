import Foundation
import Networking

// MARK: GetCipherRequest

/// A request for retrieving the details of a cipher.
///
struct GetCipherRequest: Request {
    typealias Response = CipherDetailsResponseModel

    /// The id of the cipher to retrieve details for.
    let cipherId: String

    var path: String { "/ciphers/\(cipherId)" }

    let method: HTTPMethod = .get

    /// Creates a new `GetCipherRequest`.
    ///
    /// - Parameter cipherId: The id of the cipher to retrieve details for.
    ///
    init(cipherId: String) {
        self.cipherId = cipherId
    }
}
