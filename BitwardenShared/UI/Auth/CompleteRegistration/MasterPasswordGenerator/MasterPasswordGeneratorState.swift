// MARK: - MasterPasswordGeneratorState

/// An object that defines the current state of a `MasterPasswordGeneratorView`.
///
struct MasterPasswordGeneratorState: Equatable {
    // MARK: Properties

    /// The generated master password.
    var generatedPassword: String = ""
}
