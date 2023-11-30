import BitwardenSdk
import Foundation

// MARK: - CustomFieldState

/// An object that represents a custom field in the UI.
///
struct CustomFieldState: Equatable, Hashable {
    // MARK: Properties

    /// A boolean representation of `value`. Used for `.boolean` field types.
    var booleanValue: Bool { value == "true" }

    /// A flag indicating if the password is visible.
    var isPasswordVisible: Bool = false

    /// The type of value that the field is linked to for a linked field type.
    let linkedIdType: LinkedIdType?

    /// The field's name.
    let name: String?

    /// The field's type.
    let type: FieldType

    /// The field's value.
    let value: String?
}

extension CustomFieldState {
    // MARK: Initialization

    init(fieldView: BitwardenSdk.FieldView) {
        self.init(
            isPasswordVisible: false,
            linkedIdType: fieldView.linkedId.flatMap(LinkedIdType.init),
            name: fieldView.name,
            type: FieldType(fieldType: fieldView.type),
            value: fieldView.value
        )
    }

    init(fieldView: BitwardenSdk.FieldView, isPasswordVisible: Bool = false) {
        self.init(
            isPasswordVisible: isPasswordVisible,
            linkedIdType: fieldView.linkedId.flatMap(LinkedIdType.init),
            name: fieldView.name,
            type: FieldType(fieldType: fieldView.type),
            value: fieldView.value
        )
    }
}
