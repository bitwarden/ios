import Networking

/// API response model for the PUT /ciphers/share bulk share request.
///
/// This wraps a list of `CipherMiniResponseModel` in the server's standard list response format.
///
struct BulkShareCiphersResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The list of ciphers that were shared.
    let data: [CipherMiniResponseModel]
}
