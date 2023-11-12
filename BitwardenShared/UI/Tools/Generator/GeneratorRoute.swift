/// A route to a specific screen in the generator tab.
///
public enum GeneratorRoute: Equatable, Hashable {
    /// A route to cancel the generator.
    case cancel

    /// A route to complete the generator with the provided value
    case complete(type: GeneratorType, value: String)

    /// A route to the generator screen.
    case generator(staticType: GeneratorType? = nil)
}
