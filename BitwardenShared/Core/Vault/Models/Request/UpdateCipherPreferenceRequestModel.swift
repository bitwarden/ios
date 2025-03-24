import Networking

/// API request model for updating a cipher's preference.
///
struct UpdateCipherPreferenceRequestModel: JSONRequestBody, Equatable {
    // MARK: Properties

    /// The optional folder id the cipher should be moved to.
    let folderId: String?

    /// The new favorite status of the cipher.
    let favorite: Bool
}
