import BitwardenResources

// MARK: - Alert + Select Language

public extension Alert {
    // MARK: Methods

    /// Show the alert notifying the user that the language has been changed.
    ///
    /// - Parameters:
    ///   - newLanguage: The title of the new language.
    ///   - action: The action to run after the user clicks ok.
    /// - Returns: An alert confirming the language change.
    ///
    @MainActor
    static func languageChanged(to newLanguage: String, action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.languageChangeXDescription(newLanguage),
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default) { _ in
                    action()
                },
            ],
        )
    }
}
