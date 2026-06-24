import Foundation
import Networking

// MARK: - FormsMapResponseModel

/// The response model for the Forms Map from the map-the-web repository.
///
struct FormsMapResponseModel: Equatable, JSONResponse {
    // MARK: Types

    private enum CodingKeys: String, CodingKey {
        case hosts
        case schemaVersion
    }

    // MARK: Properties

    /// The host entries keyed by hostname. Null-valued entries are excluded during decoding.
    let hosts: [String: FormsMapHostEntry]

    /// The schema version of the map.
    let schemaVersion: String

    // MARK: Codable

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hosts = try container.decode([String: FormsMapHostEntry?].self, forKey: .hosts)
            .compactMapValues { $0 }
        schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
    }
}

// MARK: - FormsMapHostEntry

/// Form descriptions for a specific host.
///
struct FormsMapHostEntry: Codable, Equatable {
    /// Site-wide fallback form descriptions used when no pathname-specific entry matches.
    let forms: [FormsMapContent]?

    /// Pathname-specific form descriptions.
    let pathnames: [String: FormsMapPathnameEntry]?
}

// MARK: - FormsMapPathnameEntry

/// Form descriptions for a specific pathname on a host.
///
struct FormsMapPathnameEntry: Codable, Equatable {
    /// Form descriptions for this pathname.
    let forms: [FormsMapContent]
}

// MARK: - FormsMapContent

/// Describes a single logical form on a page.
///
struct FormsMapContent: Codable, Equatable {
    /// The categorical purpose of the form (e.g. `"account-login"`, `"account-creation"`).
    let category: String

    /// CSS selectors identifying the form's container element.
    let container: [String]?

    /// CSS selectors keyed by field type (e.g. `"username"`, `"password"`).
    let fields: [String: [FormsMapSelector]]

    /// CSS selectors keyed by action type (e.g. `"submit"`).
    let actions: [String: [String]]?
}

// MARK: - FormsMapSelector

/// A CSS selector for a form field, which may be a single selector string or an ordered sequence
/// of selectors that together identify a composite field value.
///
enum FormsMapSelector: Codable, Equatable {
    /// A single CSS selector string.
    case single(String)

    /// An ordered sequence of CSS selectors composing a single field value.
    case sequence([String])

    // MARK: Codable

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .single(string)
        } else {
            self = try .sequence(container.decode([String].self))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .single(string):
            try container.encode(string)
        case let .sequence(strings):
            try container.encode(strings)
        }
    }
}
