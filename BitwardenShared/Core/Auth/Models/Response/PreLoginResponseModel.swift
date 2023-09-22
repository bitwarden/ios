import Foundation
import Networking

// MARK: - PreLoginResponseModel

/// The response returned from the API upon sending a pre login request.
///
/// Contains information necessary for encrypting the user's password for login.
///
struct PreLoginResponseModel: JSONResponse {
    // MARK: Static Properties

    static let decoder = JSONDecoder()

    // MARK: Properties

    /// The type of kdf algorithm to use for encryption.
    var kdf: KdfType

    /// The number of iterations to use with the kdf algorithm.
    var kdfIterations: Int

    /// The amount of memory to use with the kdf algorithm.
    var kdfMemory: Int?

    /// The number of threads to use with the kdf algorithm.
    var kdfParallelism: Int?
}
