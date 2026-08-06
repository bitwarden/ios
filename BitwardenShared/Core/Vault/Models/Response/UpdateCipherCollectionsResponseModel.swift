import Foundation
import Networking

/// API response model for updating a cipher's collections via the `_v2` endpoint.
///
struct UpdateCipherCollectionsResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The updated cipher, or `nil` if the user no longer has access to it.
    let cipher: CipherDetailsResponseModel?
}
