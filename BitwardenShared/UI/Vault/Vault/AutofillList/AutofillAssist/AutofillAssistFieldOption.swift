import Foundation

// MARK: - AutofillAssistFieldOption

/// A selectable option representing a page field that can be mapped for autofill assist.
///
struct AutofillAssistFieldOption: Equatable, Identifiable {
    // MARK: Properties

    /// A display label describing the field.
    let displayLabel: String

    /// The field's OP ID used during autofill script execution.
    let opId: String

    /// The most stable identifier for this field, used for persistent mappings.
    /// Uses `htmlId`/`htmlName`/`labelTag`/`placeholder` when available; falls back to `opId`.
    /// opId-based identifiers are only reliable within the same page session.
    let stableIdentifier: String

    // MARK: Identifiable

    var id: String { opId }
}

// MARK: - Factory

extension AutofillAssistFieldOption {
    /// Creates a list of selectable field options from page details.
    ///
    /// Includes all viewable, non-hidden, non-button input fields.
    /// Fields with DOM identifiers (`htmlId`, `htmlName`, etc.) use those as stable identifiers
    /// for persistence across page loads. Fields without any DOM identifiers fall back to their
    /// `opId`, which is reliable within the same page session.
    ///
    /// - Parameter pageDetails: The parsed web page details.
    /// - Returns: An array of field options ordered by element position.
    ///
    static func from(pageDetails: PageDetails?) -> [AutofillAssistFieldOption] {
        guard let pageDetails else { return [] }
        return pageDetails.fields.compactMap { field in
            let type = field.type?.lowercased()
            guard type != "hidden",
                  type != "button",
                  field.viewable,
                  field.disabled != true,
                  field.readOnly != true
            else { return nil }

            let stableIdentifier = field.stableIdentifier ?? field.opId
            let label = field.displayLabel

            return AutofillAssistFieldOption(
                displayLabel: label,
                opId: field.opId,
                stableIdentifier: stableIdentifier,
            )
        }
    }
}
