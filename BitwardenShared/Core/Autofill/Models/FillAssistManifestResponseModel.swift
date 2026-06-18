import Foundation
import Networking

// MARK: - FillAssistManifestResponseModel

/// The response model for the Fill-Assist manifest from the map-the-web repository.
///
struct FillAssistManifestResponseModel: Equatable, JSONResponse {
    /// The build identifier for this release (e.g. `"v20260611.1"`).
    let buildId: String

    /// The git SHA the release was built from.
    let gitSha: String

    /// The available map artifacts, keyed by map name then by major schema version (e.g. `"v1"`).
    let maps: [String: [String: FillAssistManifestEntryModel]]

    /// The ISO 8601 timestamp when this manifest was produced.
    let timestamp: String
}

// MARK: - FillAssistManifestEntryModel

/// Describes a single versioned artifact entry within the Fill-Assist manifest.
///
struct FillAssistManifestEntryModel: Codable, Equatable {
    /// The content identifier for the artifact in `sha256:<hex>` format.
    let cid: String

    /// Whether this major version has entered its end-of-life support window.
    let deprecated: Bool?

    /// The filename of the artifact (e.g. `"forms.v1.json"`).
    let filename: String

    /// The filename of the JSON Schema for this artifact (e.g. `"forms.v1.schema.json"`).
    let schema: String
}
