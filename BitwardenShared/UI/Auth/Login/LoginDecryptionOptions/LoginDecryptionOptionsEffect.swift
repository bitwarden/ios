// MARK: - LoginDecryptionOptionsEffect

/// Effects that can be processed by a `LoginDecryptionOptionsProcessor`.
enum LoginDecryptionOptionsEffect: Equatable {
    /// The approve with other device button was pressed.
    case approveWithOtherDevicePressed

    /// The approve with master password button was pressed.
    case approveWithMasterPasswordPressed

    /// The continue button was pressed.
    case continuePressed

    /// The load user login decryption options.
    case loadLoginDecryptionOptions

    /// The not you button was pressed.
    case notYouPressed

    /// The request admin approval button was pressed.
    case requestAdminApprovalPressed
}
