import Combine
import Foundation

// MARK: - StateProcessor

/// A generic `Processor` which may be subclassed to easily build a `Processor` with the typical
/// properties, connections, and behaviors.
open class StateProcessor<State: Sendable, Action: Sendable, Effect: Sendable>: Processor {
    // MARK: Properties

    /// The processor's current state.
    open var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    /// A publisher that publishes the processor's state when it changes.
    open var statePublisher: AnyPublisher<State, Never> {
        stateSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: Private properties

    /// A subject used to store and publish the current state.
    private var stateSubject: CurrentValueSubject<State, Never>

    // MARK: Initialization

    /// Initializes a `StateProcessor`.
    ///
    /// - Parameter state: The initial state of the processor.
    public init(state: State) {
        stateSubject = CurrentValueSubject(state)
    }

    /// Initializes a `StateProcessor` with an unused (`Void`) state.
    ///
    public init() where State == Void {
        stateSubject = CurrentValueSubject(())
    }

    /// Performs an asynchronous effect.
    ///
    /// Override this method in subclasses to customize its behavior.
    ///
    /// - Parameter effect: The effect to perform.
    ///
    open func perform(_ effect: Effect) async {}

    /// Receives an action from the view's store.
    ///
    /// Override this method in subclasses to customize its behavior.
    ///
    /// - Parameter action: The action to process.
    ///
    open func receive(_ action: Action) {}
}
