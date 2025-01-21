import Foundation

// MARK: - AddEditSendItemAction

/// Actions that can be processed by a `AddEditSendItemProcessor`.
///
enum AddEditSendItemAction: Equatable {
    /// The choose file button was pressed.
    case chooseFilePressed

    /// The clear expiration date button was pressed.
    case clearExpirationDatePressed

    /// The custom expiration date was changed.
    case customExpirationDateChanged(Date?)

    /// The deactivate this send toggle was changed.
    case deactivateThisSendChanged(Bool)

    /// The deletion date was changed.
    case deletionDateChanged(SendDeletionDateType)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The expiration date was changed.
    case expirationDateChanged(SendExpirationDateType)

    /// The hide my email toggle was changed.
    case hideMyEmailChanged(Bool)

    /// The hide text by default toggle was updated.
    case hideTextByDefaultChanged(Bool)

    /// The options button was pressed.
    case optionsPressed

    /// maximum access count was changed via the stepper.
    case maximumAccessCountStepperChanged(Int)

    /// maximum access count was changed via the TextField.
    case maximumAccessCountTextFieldChanged(String)

    /// The name text field was changed.
    case nameChanged(String)

    /// The notes text field was changed.
    case notesChanged(String)

    /// The password text field was changed.
    case passwordChanged(String)

    /// The password visibility was changed.
    case passwordVisibleChanged(Bool)

    /// A forwarded profile switcher action.
    case profileSwitcher(ProfileSwitcherAction)

    /// The text value text field was changed.
    case textChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The type picker was changed.
    case typeChanged(SendType)
}
