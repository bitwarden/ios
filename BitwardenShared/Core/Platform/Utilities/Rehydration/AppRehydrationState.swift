import Foundation

/// The state used for rehydration after unlocking.
struct AppRehydrationState: Codable {
    /// The target to rehydrate with additional data if needed.
    let target: RehydratableTarget
    /// The expiration time to rehydrate, after that the rehydration process won't be done.
    let expirationTime: Date
}
