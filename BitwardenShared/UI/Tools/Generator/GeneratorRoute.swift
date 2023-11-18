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
    case generator(staticType: GeneratorType? = nil)

    /// A route to the generator history screen.
    case generatorHistory
}
