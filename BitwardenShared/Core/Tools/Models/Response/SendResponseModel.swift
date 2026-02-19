import Foundation
import Networking

/// API response model for a send.
///
struct SendResponseModel: Codable, Equatable, JSONResponse {
    // MARK: Properties

    /// The number of times the send has been accessed.
    let accessCount: UInt32

    /// The identifier used to access the send.
    let accessId: String

    /// The authentication type for this send.
    let authType: SendAuthType?

    /// The deletion date of the send.
    let deletionDate: Date

    /// Whether the send is disabled.
    let disabled: Bool

    /// Comma-separated list of emails that may access the send using OTP
    /// authentication. Mutually exclusive with password.
    let emails: String?

    /// The expiration date of the send.
    let expirationDate: Date?

    /// The file included in the send.
    let file: SendFileModel?

    /// Whether the user's email address should be hidden from recipients.
    let hideEmail: Bool

    /// The send's identifier.
    let id: String

    /// The key used to decrypt the send.
    let key: String

    /// The maximum number of times the send can be accessed.
    let maxAccessCount: UInt32?

    /// The name of the send.
    let name: String

    /// Notes about the send.
    let notes: String?

    /// An optional password used to restrict access to the send.
    let password: String?

    /// The date of the send's last revision.
    let revisionDate: Date

    /// The text included in the send.
    let text: SendTextModel?

    /// The type of data in the send.
    let type: SendType
}
