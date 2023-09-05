import BitwardenShared
import Combine

class MockProcessor<State: Sendable, Action: Sendable, Effect: Sendable>: Processor {
    var dispatchedActions = [Action]()
    var effects: [Effect] = []
    let stateSubject: CurrentValueSubject<State, Never>

    var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    init(state: State) {
        stateSubject = CurrentValueSubject(state)
    }

    func receive(_ action: Action) {
        dispatchedActions.append(action)
    }

    func perform(_ effect: Effect) async {
        effects.append(effect)
    }
}
