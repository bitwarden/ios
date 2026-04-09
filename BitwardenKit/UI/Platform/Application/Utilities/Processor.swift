import Combine
import Foundation

/// A processor is responsible for receiving and processing dispatched actions. Generally a
/// processor will mutate local state based on the action it receives.
///
@MainActor
public protocol Processor: AnyObject, Sendable {
    associatedtype Action: Sendable
    associatedtype Effect: Sendable
    associatedtype State: Sendable

    /// The processor's current state.
    var state: State { get }

    /// A publisher that publishes the processor's state when it changes.
    var statePublisher: AnyPublisher<State, Never> { get }

    /// Performs an asynchronous effect.
    ///
    /// - Parameter effect: The effect to perform.
    ///
    func perform(_ effect: Effect) async

    /// Receives an action from the view's store.
    ///
    /// - Parameter action: The action to process.
    ///
    func receive(_ action: Action)
}
