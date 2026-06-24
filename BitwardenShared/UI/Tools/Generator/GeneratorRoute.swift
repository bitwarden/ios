/// A route to a specific screen in the generator tab.
///
public enum GeneratorRoute: Equatable, Hashable {
    /// A route to cancel the generator.
    case cancel

    /// A route to complete the generator with the provided value
    ///
    /// - Parameters:
    ///   - type: The type of value that was generated.
    ///   - value: The generated value to return to the caller.
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
    case generator(staticType: GeneratorType? = nil, emailWebsite: String? = nil, passwordRules: String? = nil)

    /// A route to the generator history screen.
    case generatorHistory
}
