/// API model for a cipher custom field.
///
struct CipherFieldModel: Codable, Equatable {
    // MARK: Properties

    /// The type of value that the field is linked to for a linked field type.
    let linkedId: LinkedIdType?

    /// The field's name.
    let name: String?

    /// The field's type.
    let type: FieldType

    /// The field's value.
    let value: String?
}
