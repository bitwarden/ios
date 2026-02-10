import BitwardenKit

// MARK: - LoginDecryptionOptionsState

/// An object that defines the current state of a `LoginDecryptionOptionsView`.
///
struct LoginDecryptionOptionsState: Equatable {
    // MARK: Properties

    /// Whether the approve with master password button is enabled.
    var shouldShowApproveMasterPasswordButton: Bool = false

    /// Whether the approve with other device button is enabled.
    var shouldShowApproveWithOtherDeviceButton: Bool = false

    /// Whether the continue button is enabled.
    var shouldShowContinueButton: Bool = false

    /// Email of the active user to be displayed
    var email: String = ""

    /// Whether the remember device toggle is on.
    var isRememberDeviceToggleOn: Bool = true

    /// The organization identifier being used during the single-sign process.
    var orgIdentifier: String?

    /// Whether the request admin approval button is enabled.
    var shouldShowAdminApprovalButton: Bool = false

    /// A toast message to show in the view.
    var toast: Toast?
}
