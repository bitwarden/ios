import Foundation
import TestHelpers

public extension APITestData {
    /// A standard Bitwarden error message of "You do not have permissions to edit this."
    static let bitwardenErrorMessage = loadFromJsonBundle(resource: "BitwardenErrorMessage")
}
