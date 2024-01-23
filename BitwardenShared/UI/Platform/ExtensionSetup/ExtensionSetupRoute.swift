// MARK: - ExtensionSetupRoute

/// A route to a specific screen in the extension setup flow.
///
public enum ExtensionSetupRoute: Equatable {
    /// A route to the extension activation screen.
    case extensionActivation(type: ExtensionActivationType)
}
