import AuthenticatorShared

extension Store {
    static func mock(state: State) -> Store<State, Action, Effect> {
        Store(processor: MockProcessor(state: state))
    }
}
