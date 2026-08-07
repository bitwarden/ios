/// A route to a specific screen in the generator tab.
///
public enum GeneratorRoute: Equatable, Hashable {
    /// A route to cancel the generator.
    case cancel

    /// A route to complete the generator with the provided value
    case complete(type: GeneratorType, value: String)

    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route to the generator screen.
    ///
    /// - Parameters:
    ///   - staticType: When set, locks the generator to this type and prevents the user from switching.
    ///   - emailWebsite: The website used to pre-populate the email generator's website field.
    ///   - passwordRules: A password rules string (from the AutoFill credential API) used to
    ///     constrain password generation to site-specific requirements.
    ///   - savePasswordHistory: When `false`, generated passwords are not saved to password history.
    ///     Use when the vault is not unlocked (e.g. the generate-password credential extension flow).
    case generator(
        staticType: GeneratorType? = nil,
        emailWebsite: String? = nil,
        passwordRules: String? = nil,
        savePasswordHistory: Bool = true,
    )

    /// A route to the generator history screen.
    case generatorHistory
}
