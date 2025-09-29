import Foundation
import Networking

public extension JSONResponse {
    /// The decoder used by default to decode JSON responses from the API.
    static var decoder: JSONDecoder { .pascalOrSnakeCaseDecoder }
}
