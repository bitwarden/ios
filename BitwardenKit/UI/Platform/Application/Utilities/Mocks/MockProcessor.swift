import BitwardenKit
import Combine

open class MockProcessor<State: Sendable, Action: Sendable, Effect: Sendable>: Processor {
    public var dispatchedActions = [Action]()
    public var effects: [Effect] = []
    let stateSubject: CurrentValueSubject<State, Never>

    public var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    public var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public init(state: State) {
        stateSubject = CurrentValueSubject(state)
    }

    public func receive(_ action: Action) {
        dispatchedActions.append(action)
    }

    public func perform(_ effect: Effect) async {
        effects.append(effect)
    }
}
