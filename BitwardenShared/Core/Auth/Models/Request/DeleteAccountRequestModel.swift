import Foundation
import Networking

// MARK: - DeleteAccountRequestModel

/// The data to include in the body of a `DeleteAccountRequest`.
///
struct DeleteAccountRequestModel: JSONRequestBody {
    // MARK: Static Properties

    static var encoder = JSONEncoder()

    // MARK: Properties

    /// The encrypted master password.
    var masterPasswordHash: String
}
