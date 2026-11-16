// MARK: - SeedResponse

/// The seeder's response to running a scene.
///
struct SeedResponse<Result: Decodable>: Decodable {
    /// The values the seeder made unique for this play, keyed by the value that was requested.
    let mangleMap: [String: String?]?

    /// The scene's result.
    let result: Result
}
