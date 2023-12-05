import BitwardenSdk
import Foundation

// MARK: - LoginItemState

/// The state for viewing a login item.
struct LoginItemState: Equatable {
    // MARK: Properties

    /// The Cipher underpinning the state
    var cipher: CipherView

    /// A flag indicating if the password is visible.
    var isPasswordVisible = false

    /// The editable properties of the Login Item
    var properties: CipherItemProperties

    // MARK: Initializers

    /// Creates a new LoginItemState
    ///
    /// - Parameter cipherView: The Cipher View the item represents.
    ///
    init?(cipherView: CipherView) {
        guard let properties = CipherItemProperties.from(cipherView) else { return nil }
        cipher = cipherView
        self.properties = properties
    }

    // MARK: Methods

    /// Toggles the password visibility for the specified custom field.
    ///
    /// - Parameter customFieldState: The custom field to update.
    ///
    mutating func togglePasswordVisibility(for customFieldState: CustomFieldState) {
        if let index = properties.customFields.firstIndex(of: customFieldState) {
            properties.customFields[index].isPasswordVisible.toggle()
        }
    }
}
