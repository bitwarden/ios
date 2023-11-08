import Foundation
import Networking

extension JSONRequestBody {
    /// The encoder used by default to encode JSON request bodies for the API.
    static var encoder: JSONEncoder { .defaultEncoder }
}
