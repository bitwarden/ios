import Networking

/// API request model for updating the collections for a cipher.
///
struct CipherCollectionsRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The list of collection IDs that the cipher should be included in.
    let collectionIds: [String]
}
