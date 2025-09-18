import Foundation
import Networking

/// API response for deleting an attachment.
///
struct DeleteAttachmentResponse: JSONResponse, Codable, Equatable {
    // MARK: Types

    /// Data model for the cipher properties returned from the delete attachment API response.
    ///
    struct DeleteAttachmentResponseCipher: Codable, Equatable {
        /// The date the cipher was last updated.
        let revisionDate: Date
    }

    // MARK: Properties

    /// The updated cipher properties.
    let cipher: DeleteAttachmentResponseCipher
}
