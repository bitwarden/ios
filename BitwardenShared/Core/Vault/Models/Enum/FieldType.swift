/// The type of data stored in a cipher custom field.
///
enum FieldType: Int, Codable {
    /// The field stores freeform input.
    case text = 0

    /// The field stores freeform input that is hidden from view.
    case hidden = 1

    /// The field stores a boolean value.
    case boolean = 2

    /// The field value is linked to the item's username or password.
    case linked = 3
}
