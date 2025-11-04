import BitwardenKit

public extension Store {
    /// Creates a Store with a mocked processor given a state.
    /// - Parameter state: The state to initialize the mock processor with.
    /// - Returns: A new `Store` with a `MockProcessor` having the passed `state`.
    static func mock(state: State) -> Store<State, Action, Effect> {
        Store(processor: MockProcessor(state: state))
    }
}
