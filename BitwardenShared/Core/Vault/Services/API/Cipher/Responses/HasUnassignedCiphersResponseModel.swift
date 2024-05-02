import Foundation
import Networking

// MARK: - HasUnassignedCiphersResponseModel

/// An object containing a value indicating if the user has unassigned ciphers or not.
struct HasUnassignedCiphersResponseModel: JSONResponse {
    static var decoder = JSONDecoder()

    // MARK: Properties

    /// A flag indicating if the user has unassigned ciphers or not.
    var hasUnassignedCiphers: Bool

    // MARK: Initialization

    /// Creates a new `HasUnassignedCiphersResponseModel` instance.
    ///
    /// - Parameter hasUnassignedCiphers: A flag indicating if the user has unassigned ciphers or not.
    init(hasUnassignedCiphers: Bool) {
        self.hasUnassignedCiphers = hasUnassignedCiphers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        hasUnassignedCiphers = try container.decode(Bool.self)
    }

}
