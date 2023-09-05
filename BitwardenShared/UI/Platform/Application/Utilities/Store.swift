import Combine
import SwiftUI

/// A `Store` provides an interface for observing and modifying state between a `Processor` and a
/// `View`. A `View` can send actions to the `Processor` through the store and can observe changes
/// that the `Processor` makes to the state.
///
@MainActor
open class Store<State: Sendable, Action: Sendable, Effect: Sendable>: ObservableObject {
    // MARK: Properties

    /// A cancellable object for the processor's state publisher subscription.
    private var cancellable: AnyCancellable?

    /// The current state of the store. This is updated from a `Processor` and is able to be
    /// observed by a view.
    @Published private(set) var state: State

    /// A closure that is called when an effect is performed by the view.
    private var perform: ((Effect) async -> Void)?

    /// A closure that is called when an action is sent from the view.
    private var receive: ((Action) -> Void)?

    // MARK: Initialization

    /// Initialize a `Store` from a `Processor`. This connects the processor to the `Store`. When
    /// the processor's state changes, the store's state will update, allowing a view to observe
    /// changes to the state and re-render. When an action is sent to the store from a view, the
    /// processor will receive the action for processing.
    ///
    /// - Parameter processor: The `Processor` that will receive actions from the store and update
    ///     the store's state.
    ///
    public init<P: Processor>(processor: P) where P.Action == Action, P.Effect == Effect, P.State == State {
        state = processor.state
        receive = { processor.receive($0) }
        perform = { await processor.perform($0) }
        cancellable = processor.statePublisher.sink { [weak self] in self?.state = $0 }
    }

    /// Initialize a new `Store` from an existing `Store`.
    ///
    /// - Parameters:
    ///   - parentStore: The existing `Store` used to create the new `Store`.
    ///   - parentToChildState: A closure that maps state from the parent store to the child store.
    ///   - map: A closure that maps actions from the `Store` to an action of the parent `Store`.
    ///
    public init<ParentState, ParentAction, ParentEffect>(
        parentStore: Store<ParentState, ParentAction, ParentEffect>,
        state parentToChildState: @escaping (ParentState) -> State,
        mapAction: @escaping (Action) -> ParentAction,
        mapEffect: @escaping (Effect) -> ParentEffect
    ) {
        state = parentToChildState(parentStore.state)
        receive = { parentStore.send(mapAction($0)) }
        perform = { await parentStore.perform(mapEffect($0)) }
        cancellable = parentStore.$state.sink { [weak self] in self?.state = parentToChildState($0) }
    }

    // MARK: Methods

    /// Send an action to the store. The action will be received by the store's processor or a
    /// parent store.
    ///
    /// - Parameter action: The action to send.
    ///
    open func send(_ action: Action) {
        receive?(action)
    }

    /// Performs an asynchronous effect using the store.
    ///
    /// - Parameter effect: The effect to perform.
    ///
    open func perform(_ effect: Effect) async {
        await perform?(effect)
    }

    /// Creates a child `Store` from an existing `Store`. This can be used to create a new `Store`
    /// for a view that may be used in conjunction with other stores in the application. Any
    /// actions sent from the child store are mapped to a parent's action and sent back to the
    /// parent store.
    ///
    /// - Parameters:
    ///   - state: The store's initial state.
    ///   - map: A closure that provides a mapping from an action sent by the child store to the
    ///     parent store's action.
    /// - Returns: A child `Store` created from an existing `Store`.
    ///
    open func child<ChildState, ChildAction, ChildEffect>(
        state: @escaping (State) -> ChildState,
        mapAction: @escaping (ChildAction) -> Action,
        mapEffect: @escaping (ChildEffect) -> Effect
    ) -> Store<ChildState, ChildAction, ChildEffect> {
        Store<ChildState, ChildAction, ChildEffect>(
            parentStore: self,
            state: state,
            mapAction: mapAction,
            mapEffect: mapEffect
        )
    }

    /// Creates a `Binding` whose value is set from the store's state. When the value is changed,
    /// the specified action is sent to the store so that the processor can update its state.
    ///
    /// - Parameters:
    ///   - get: A closure that provides a value for the binding from the store's state.
    ///   - stateToAction: A closure that provides a mapping from the binding's value to an action
    ///     that is sent to the store when the value changes.
    /// - Returns: A `Binding` whose value is set from the store's state which triggers an action
    ///     to be sent back to the store when the value changes.
    ///
    open func binding<LocalState>(
        get: @escaping (State) -> LocalState,
        send stateToAction: @escaping (LocalState) -> Action
    ) -> Binding<LocalState> {
        Binding(
            get: { get(self.state) },
            set: { value, _ in
                self.send(stateToAction(value))
            }
        )
    }

    /// Creates a `Binding` whose value is set from the store's state. This binding is only used for _retrieving_
    /// values, and cannot be used to set values in the state. This binding should only be used when a value in a
    /// store's state needs to be observed, but not updated.
    ///
    /// - Parameter get: A closure that provides a value for the binding from the store's state.
    /// - Returns: A `Binding` whose value is set from the store's state and does not notify the store if the value is
    ///     updated.
    ///
    open func binding<LocalState>(get: @escaping (State) -> LocalState) -> Binding<LocalState> {
        Binding(
            get: { get(self.state) },
            set: { _ in }
        )
    }
}
