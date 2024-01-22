import BitwardenSdk
import Foundation

// MARK: - CustomFieldState

/// An object that represents a custom field in the UI.
///
struct CustomFieldState: Equatable, Hashable, Identifiable {
    // MARK: Properties

    /// A boolean representation of `value`. Used for `.boolean` field types.
    var booleanValue: Bool { value == "true" }

    /// A unique identifier for this custom field.
    var id: String

    /// A flag indicating if the password is visible.
    var isPasswordVisible: Bool = false

    /// The type of value that the field is linked to for a linked field type.
    let linkedIdType: LinkedIdType?

    /// The field's name.
    var name: String?

    /// The field's type.
    let type: FieldType

    /// The field's value.
    var value: String?
}

extension CustomFieldState {
    // MARK: Initialization

    /// Creates a new `CustomFieldState`.
    ///
    /// - Parameters:
    ///   - id: The id for this custom field.
    ///   - isPasswordVisible: A flag indicating if the password is visible this custom field.
    ///   - name: The name of this custom field.
    ///   - type: The `FieldType` for this custom field.
    ///   - value:The value of this custom field.
    ///
    init(
        id: String = UUID().uuidString,
        isPasswordVisible: Bool? = nil,
        linkedIdType: LinkedIdType? = nil,
        name: String?,
        type: FieldType,
        value: String? = nil
    ) {
        self.init(id: id, linkedIdType: linkedIdType, name: name, type: type, value: value)
    }

    /// Creates a CustomFieldState from an SDK `FieldView`
    ///
    /// - Parameter fieldView: A `BitwardenSdk.FieldView` used to populate the custom field.
    ///
    init(fieldView: BitwardenSdk.FieldView) {
        self.init(
            isPasswordVisible: false,
            linkedIdType: fieldView.linkedId.flatMap(LinkedIdType.init),
            name: fieldView.name,
            type: FieldType(fieldType: fieldView.type),
            value: fieldView.value
        )
    }
}
