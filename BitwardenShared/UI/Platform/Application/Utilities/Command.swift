import Foundation

/// A type that represents a single execution of an effect.
///
public struct Command<Action: Sendable, State: Sendable>: Sendable {
    // MARK: Properties

    /// The action received by a `Store` that triggered the effect.
    public let action: Action

    /// The state of the `Store` when the action occurred.
    public let state: State

    /// A closure that will cancel the `Task` that was created to execute the command.
    public var cancel: @Sendable () -> Void = {}

    /// A closure that will asynchronously send an `Action` to the store. This may be used to
    /// communicate changes that should occur as a result of performing the command.
    public let send: @Sendable (Action) async -> Void
}
