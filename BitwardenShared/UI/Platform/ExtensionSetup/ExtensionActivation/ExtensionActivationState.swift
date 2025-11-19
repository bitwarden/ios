import BitwardenResources

// MARK: - ExtensionActivationState

/// An object that defines the current state of a `ExtensionActivationView`.
///
struct ExtensionActivationState: Equatable, Sendable {
    // MARK: Properties

    /// The type of extension to show the activation view for.
    var extensionType: ExtensionActivationType

    /// The message text in the view.
    var message: String {
        switch extensionType {
        case .appExtension:
            Localizations.extensionSetup +
                .newLine +
                Localizations.extensionSetup2
        case .autofillExtension:
            Localizations.autofillSetup +
                .newLine +
                Localizations.autofillSetup2
        }
    }

    /// The title for the navigation bar.
    var navigationBarTitle: String {
        extensionType == .autofillExtension ? Localizations.accountSetup : ""
    }

    /// Whether or not to show the new or legacy view.
    var showLegacyView: Bool {
        extensionType == .appExtension
    }

    /// The title text in the view.
    var title: String {
        switch extensionType {
        case .appExtension:
            Localizations.extensionActivated
        case .autofillExtension:
            Localizations.autofillActivated
        }
    }
}
