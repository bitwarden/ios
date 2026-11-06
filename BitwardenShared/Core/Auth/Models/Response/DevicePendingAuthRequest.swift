import Foundation

// MARK: - DevicePendingAuthRequest

/// The pending authentication request associated with a device, as reported directly by the
/// `/devices` endpoint.
///
struct DevicePendingAuthRequest: Codable, Equatable, Hashable, Sendable {
    // MARK: Properties

    /// The date the pending authentication request was created.
    let creationDate: Date

    /// The unique identifier of the pending authentication request.
    let id: String
}
