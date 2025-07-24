import BitwardenResources

/// The type of data stored in a cipher custom field.
///
enum FieldType: Int, Codable, Menuable {
    /// The field stores freeform input.
    case text = 0

    /// The field stores freeform input that is hidden from view.
    case hidden = 1

    /// The field stores a boolean value.
    case boolean = 2

    /// The field value is linked to another field in the item.
    case linked = 3

    /// The localized title of the `FieldType`.
    var localizedName: String {
        switch self {
        case .boolean:
            Localizations.fieldTypeBoolean
        case .hidden:
            Localizations.fieldTypeHidden
        case .linked:
            Localizations.fieldTypeLinked
        case .text:
            Localizations.fieldTypeText
        }
    }
}
