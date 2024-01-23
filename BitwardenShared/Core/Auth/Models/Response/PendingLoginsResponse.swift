import Foundation
import Networking

// MARK: - PendingLoginsResponse

/// The response returned from the API when requesting the pending login requests.
///
struct PendingLoginsResponse: JSONResponse {
    static var decoder = JSONDecoder.defaultDecoder

    // MARK: Properties

    /// The data returned by the API request.
    let data: [LoginRequest]
}
