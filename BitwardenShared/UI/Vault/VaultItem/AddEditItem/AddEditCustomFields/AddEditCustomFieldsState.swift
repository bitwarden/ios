import BitwardenSdk
import Foundation

/// A `Sendable` type to describe the state of a custom fields for `AddEditCustomFieldsView`.
///
struct AddEditCustomFieldsState: Sendable, Equatable {
    // MARK: Properties

    /// The custom fields.
    var customFields: [CustomFieldState] = []
}
