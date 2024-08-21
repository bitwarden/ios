// MARK: - ExtensionActivationState

/// An object that defines the current state of a `ExtensionActivationView`.
///
struct ExtensionActivationState: Equatable, Sendable {
    // MARK: Properties

    /// The type of extension to show the activation view for.
    var extensionType: ExtensionActivationType
}
