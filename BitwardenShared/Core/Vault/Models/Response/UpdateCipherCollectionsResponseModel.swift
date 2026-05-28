import Foundation
import Networking

/// API response model for updating a cipher's collections via the `_v2` endpoint.
///
struct UpdateCipherCollectionsResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The updated cipher, or `nil` if the user no longer has access.
    let cipher: CipherDetailsResponseModel?

    /// Whether the cipher is now unavailable to the current user (e.g. because they removed
    /// themselves from all collections that granted them Can Manage access).
    let unavailable: Bool
}
