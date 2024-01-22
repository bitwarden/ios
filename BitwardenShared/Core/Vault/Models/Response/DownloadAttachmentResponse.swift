import Foundation
import Networking

// MARK: - DownloadAttachmentResponse

/// API response model for downloading a cipher attachment's data.
///
struct DownloadAttachmentResponse: JSONResponse, Equatable {
    // MARK: Properties

    /// The url that contains the data of the attachment to download.
    let url: URL
}
