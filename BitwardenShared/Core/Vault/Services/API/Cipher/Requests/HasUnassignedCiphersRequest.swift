import Foundation
import Networking

// MARK: - HasUnassignedCiphersRequest

/// A request for determining if a user has any unassigned ciphers.
///
struct HasUnassignedCiphersRequest: Request {
    typealias Response = HasUnassignedCiphersResponseModel

    let path = "/ciphers/has-unassigned-ciphers"
}
