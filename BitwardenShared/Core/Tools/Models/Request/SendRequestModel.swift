import BitwardenSdk
import Foundation
import Networking

// MARK: - SendRequestModel

/// API request model for adding or updating a Send.
///
struct SendRequestModel: JSONRequestBody {
    // MARK: Properties

    /// The authentication type for this send.
    var authType: SendAuthType?

    /// The date this Send will be deleted.
    var deletionDate: Date

    /// A flag indicating if this Send has been disabled.
    var disabled: Bool

    /// Comma-separated list of emails that can access the send (for email auth type).
    var emails: String?

    /// The date this Send will expire.
    var expirationDate: Date?

    /// The file data for a File type Send.
    var file: SendFileModel?

    /// The length of the file.
    var fileLength: Int?

    /// If the user's email address should be hidden when viewing the Send in
    /// the web interface.
    var hideEmail: Bool?

    /// The key for this Send.
    var key: String

    /// The maximum number of times this Send can be accessed before being
    /// disabled automatically.
    var maxAccessCount: Int32?

    /// The name of the Send.
    var name: String?

    /// Notes contained within the Send.
    var notes: String?

    /// A password that controls access to this Send on the web interface.
    var password: String?

    /// The text data for a Text type Send.
    var text: SendTextModel?

    /// The type of this Send.
    var type: SendType
}
