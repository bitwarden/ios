import Foundation
import Networking

extension JSONResponse {
    /// The decoder used by default to decode JSON responses from the API.
    static var decoder: JSONDecoder { .defaultDecoder }
}
