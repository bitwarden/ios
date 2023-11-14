/// A route to a specific screen in the generator tab.
///
public enum GeneratorRoute: Equatable, Hashable {
    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route to the generator screen.
    case generator

    /// A route to the generator history screen.
    case generatorHistory
}
