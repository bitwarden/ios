// MARK: - SeedRequest

/// The body of a request asking the seeder to run a scene.
///
struct SeedRequest<Arguments: Encodable>: Encodable {
    /// The name of the scene to run.
    let template: String

    /// The arguments of the scene.
    let arguments: Arguments
}
