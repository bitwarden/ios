import Foundation

// MARK: - PageDetails

/// The parsed details of a HTML web page used to determine the fields to autofill.
///
public struct PageDetails: Codable, Equatable, Hashable {
    // MARK: Types

    // MARK: Properties

    /// The timestamp when the page details where collected.
    public let collectedTimestamp: Date

    /// The UUID of the document.
    public let documentUUID: String

    /// The document URL.
    public let documentUrl: String

    /// A list of fields in the page.
    public let fields: [Field]

    /// A list of forms in the page.
    public let forms: [String: Form]

    /// The tab URL.
    public let tabUrl: String

    /// The page's title.
    public let title: String

    /// The page's URL.
    public let url: String

    // MARK: Computed Properties

    /// Whether the list of fields contains a password field.
    public var hasPasswordField: Bool {
        fields.contains(where: { $0.type == "password" })
    }

    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(documentUUID)
    }
}

extension PageDetails.Field {
    /// A human-readable label for display in the Autofill Assist picker.
    ///
    /// Uses the following fallback chain: `labelTag` → `placeholder` → `htmlName` → `htmlId` → `opId`.
    ///
    var displayLabel: String {
        if let labelTag = labelTag?.trimmingCharacters(in: .whitespacesAndNewlines), !labelTag.isEmpty {
            return labelTag
        }
        if let placeholder, !placeholder.isEmpty {
            return placeholder
        }
        if let htmlName, !htmlName.isEmpty {
            return htmlName
        }
        if let htmlId, !htmlId.isEmpty {
            return htmlId
        }
        return opId
    }

    /// The most stable DOM identifier for this field, used for persistent URL-based mappings.
    ///
    /// Uses the fallback chain: `htmlId` → `htmlName` → `labelTag` → `placeholder`.
    /// Returns `nil` if no stable identifier is available.
    ///
    var stableIdentifier: String? {
        if let htmlId = htmlId?.trimmingCharacters(in: .whitespacesAndNewlines), !htmlId.isEmpty {
            return htmlId
        }
        if let htmlName = htmlName?.trimmingCharacters(in: .whitespacesAndNewlines), !htmlName.isEmpty {
            return htmlName
        }
        if let labelTag = labelTag?.trimmingCharacters(in: .whitespacesAndNewlines), !labelTag.isEmpty {
            return labelTag
        }
        if let placeholder = placeholder?.trimmingCharacters(in: .whitespacesAndNewlines), !placeholder.isEmpty {
            return placeholder
        }
        return nil
    }
}

public extension PageDetails {
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
        public let htmlAction: String

        /// The form's HTML ID.
        public let htmlId: String

        /// The form's HTML method.
        public let htmlMethod: String

        /// The form's HTML name.
        public let htmlName: String

        /// The form's OP ID.
        public let opId: String
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
        public let disabled: Bool?

        /// The element number of the field.
        public let elementNumber: Int

        /// The identifier of the form this field is in.
        public let form: String?

        /// The field's HTML class.
        public let htmlClass: String?

        /// The field's HTML ID.
        public let htmlId: String?

        /// The field's HTML name.
        public let htmlName: String?

        /// The left-aligned label of the field.
        public let labelLeft: String?

        /// The right-aligned label of the field.
        public let labelRight: String?

        /// The label's tag.
        public let labelTag: String?

        /// The field's type.
        public let onepasswordFieldType: String?

        /// The OP ID.
        public let opId: String

        /// The field's placeholder value.
        public let placeholder: String?

        /// Whether the field is read-only.
        public let readOnly: Bool?

        /// The field's type.
        public let type: String?

        /// The field's value.
        public let value: String?

        /// Whether the field is viewable.
        public let viewable: Bool

        /// Whether the field is visible.
        public let visible: Bool
    }
}
