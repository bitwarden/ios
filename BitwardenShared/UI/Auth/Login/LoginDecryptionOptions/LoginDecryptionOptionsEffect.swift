// MARK: - LoginDecryptionOptionsEffect

/// Effects that can be processed by a `LoginDecryptionOptionsProcessor`.
enum LoginDecryptionOptionsEffect: Equatable {
    /// The approve with other device button was pressed.
    case approveWithOtherDevicePressed

    /// The request admin approval  button was pressed.
    case requestAdminApprovalPressed

    /// The approve with master password button was pressed.
    case approveWithMasterPasswordPressed

    /// The load user login decryption options.
    case loadLoginDecryptionOptions

    /// The continue button was pressed.
    case continuePressed

    /// The not you button was pressed.
    case notYouPressed
}
