import Foundation
import Networking

// MARK: - AccountRevisionDateResponseModel

/// API response model for the account revision date request.
///
struct AccountRevisionDateResponseModel: Response {
    // MARK: Properties

    /// The account's last revision date.
    let date: Date?

    // MARK: Initialization

    init(response: HTTPResponse) throws {
        let bodyString = String(data: response.body, encoding: .utf8)
        guard let bodyString, let epochMilliseconds = TimeInterval(bodyString) else {
            date = nil
            return
        }
        date = Date(timeIntervalSince1970: epochMilliseconds / 1000)
    }
}
