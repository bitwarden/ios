import Foundation

/// Errrors related to Fido2 flows.
public enum Fido2Error: Error {
    /// Thrown when the operation to be performed is invalid under the
    /// current circumstances.
    case invalidOperationError

    /// Thrown when the Fido2 delegate has not been set up
    case noDelegateSetup

    /// Thrown when in a flow without user interaction and needs to interact with the user.
    case userInteractionRequired
}
