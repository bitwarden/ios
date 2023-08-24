import BitwardenShared
import Combine

class MockProcessor<StateType: Sendable, ActionType: Sendable, Effect: Sendable>: Processor {
    var dispatchedActions = [ActionType]()
    var effects: [Effect] = []
    let stateSubject: CurrentValueSubject<StateType, Never>

    var state: StateType {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    var statePublisher: AnyPublisher<StateType, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    init(state: StateType) {
        stateSubject = CurrentValueSubject(state)
    }

    func receive(_ action: ActionType) {
        dispatchedActions.append(action)
    }

    func perform(_ effect: Effect) async {
        effects.append(effect)
    }
}
