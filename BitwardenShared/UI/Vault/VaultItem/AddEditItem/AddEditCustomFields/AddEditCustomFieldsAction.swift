// MARK: - AddEditCustomFieldsAction

/// Actions that can be handled by an `AddEditItemProcessor`.
enum AddEditCustomFieldsAction: Equatable {
    /// The boolean field value was changed.
    case booleanFieldChanged(Bool, Int)

    /// The custom field was added.
    case customFieldAdded(FieldType, String)

    /// The custom field value was changed.
    case customFieldChanged(String, index: Int)

    /// The remove custom field button was pressed.
    case customFieldNameChanged(index: Int, newValue: String)

    /// The edit custom field name button was pressed.
    case editCustomFieldNamePressed(index: Int)

    /// The move down custom field button was pressed.
    case moveDownCustomFieldPressed(index: Int)

    /// The move up custom field button was pressed.
    case moveUpCustomFieldPressed(index: Int)

    /// The new custom field button was pressed.
    case newCustomFieldPressed

    /// The remove custom field button was pressed.
    case removeCustomFieldPressed(index: Int)

    /// A custom field type was selected.
    case selectedCustomFieldType(FieldType)

    /// The toggle password visibility button was changed.
    case togglePasswordVisibilityChanged(Bool, Int)
}
