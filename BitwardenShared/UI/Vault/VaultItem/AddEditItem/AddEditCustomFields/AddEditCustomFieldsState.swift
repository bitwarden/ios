import BitwardenSdk
import Foundation

/// A `Sendable` type to describe the state of a list of custom fields for `AddEditCustomFieldsView`.
///
struct AddEditCustomFieldsState: Sendable, Equatable {
    // MARK: Properties

    /// The cipher type.
    let cipherType: CipherType

    /// The custom fields.
    var customFields: [CustomFieldState] = []
}
