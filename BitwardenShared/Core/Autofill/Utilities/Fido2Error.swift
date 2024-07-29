import Foundation

/// Errors related to Fido2 flows.
public enum Fido2Error: Error {
    /// Thrown when decrypting FIdo2 autofill credentials returns an empty array
    /// when it's supposed to have FIdo2 credentials inside.
    case decryptFido2AutofillCredentialsEmpty

    /// The user failed to set up a Bitwarden pin.
    case failedToSetupPin

    /// Thrown when the operation to be performed is invalid under the
    /// current circumstances.
    case invalidOperationError

    /// Thrown when the Fido2 delegate has not been set up
    case noDelegateSetup

    /// Thrown when in a flow without user interaction and needs to interact with the user.
    case userInteractionRequired
}
