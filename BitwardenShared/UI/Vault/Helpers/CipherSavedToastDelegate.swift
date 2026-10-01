import BitwardenKit
import Foundation

// MARK: - CipherSavedToastDelegate

/// A `CipherItemOperationDelegate` that reports a saved item by displaying a confirmation toast,
/// leaving the presenting screen in place.
///
/// This is for screens whose own `CipherItemOperationDelegate` conformance does something other
/// than show a toast on save, and which therefore can't pass themselves as the delegate for an
/// edit started from the more options menu. `VaultItemSelectionProcessor` is one: it dismisses on
/// save so the user is returned to the vault after adding an OTP key to an existing item.
///
/// Screens are expected to hold onto their instance, since `AddEditItemProcessor` references its
/// delegate weakly.
///
@MainActor
final class CipherSavedToastDelegate: CipherItemOperationDelegate {
    // MARK: Private Properties

    /// A closure called to display a toast.
    private let handleDisplayToast: (Toast) -> Void

    // MARK: Initialization

    /// Initialize a `CipherSavedToastDelegate`.
    ///
    /// - Parameter handleDisplayToast: A closure called to display a toast.
    ///
    init(handleDisplayToast: @escaping (Toast) -> Void) {
        self.handleDisplayToast = handleDisplayToast
    }

    // MARK: Methods

    func itemUpdated(type: CipherType) -> Bool {
        handleDisplayToast(Toast(title: type.savedToastTitle))
        return true
    }
}
