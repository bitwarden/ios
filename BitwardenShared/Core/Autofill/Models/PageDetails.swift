import Foundation

// MARK: - PageDetails

/// The parsed details of a HTML web page used to determine the fields to autofill.
///
struct PageDetails: Codable, Equatable {
    // MARK: Types

    // MARK: Properties

    /// The timestamp when the page details where collected.
    let collectedTimestamp: Date

    /// The UUID of the document.
    let documentUUID: String

    /// The document URL.
    let documentUrl: String

    /// A list of fields in the page.
    let fields: [Field]

    /// A list of forms in the page.
    let forms: [String: Form]

    /// The tab URL.
    let tabUrl: String

    /// The page's title.
    let title: String

    /// The page's URL.
    let url: String

    // MARK: Computed Properties

    /// Whether the list of fields contains a password field.
    var hasPasswordField: Bool {
        fields.contains(where: { $0.type == "password" })
    }
}

extension PageDetails {
    /// A data model for a form within a web page.
    ///
    struct Form: Codable, Equatable {
        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case htmlAction
            case htmlId = "htmlID"
            case htmlName
            case htmlMethod
            case opId = "opid"
        }

        /// The action of the form.
        let htmlAction: String

        /// The form's HTML ID.
        let htmlId: String

        /// The form's HTML method.
        let htmlMethod: String

        /// The form's HTML name.
        let htmlName: String

        /// The form's OP ID.
        let opId: String
    }

    /// A data model for a field within a web page.
    ///
    struct Field: Codable, Equatable {
        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case disabled
            case elementNumber
            case form
            case htmlClass
            case htmlId = "htmlID"
            case htmlName
            case labelLeft = "label-left"
            case labelRight = "label-right"
            case labelTag = "label-tag"
            case onepasswordFieldType
            case opId = "opid"
            case placeholder
            case readOnly
            case type
            case value
            case viewable
            case visible
        }

        /// Whether the field is disabled.
        let disabled: Bool?

        /// The element number of the field.
        let elementNumber: Int

        /// The identifier of the form this field is in.
        let form: String?

        /// The field's HTML class.
        let htmlClass: String?

        /// The field's HTML ID.
        let htmlId: String?

        /// The field's HTML name.
        let htmlName: String?

        /// The left-aligned label of the field.
        let labelLeft: String?

        /// The right-aligned label of the field.
        let labelRight: String?

        /// The label's tag.
        let labelTag: String?

        /// The field's type.
        let onepasswordFieldType: String?

        /// The OP ID.
        let opId: String

        /// The field's placeholder value.
        let placeholder: String?

        /// Whether the field is read-only.
        let readOnly: Bool?

        /// The field's type.
        let type: String?

        /// The field's value.
        let value: String?

        /// Whether the field is viewable.
        let viewable: Bool

        /// Whether the field is visible.
        let visible: Bool
    }
}
