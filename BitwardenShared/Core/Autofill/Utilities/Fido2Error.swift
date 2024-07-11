import Foundation

/// Errrors related to Fido2 flows.
enum Fido2Error: Error {
    /// Thrown when the operation to be performed is invalid under the
    /// current circumstances.
    case invalidOperationError
}
