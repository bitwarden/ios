import BackgroundTasks

/// A thin wrapper around `BGTaskScheduler` used to register and schedule background app refresh
/// tasks. Exists so background task scheduling can be mocked in tests, since `BGTaskScheduler`
/// itself can't be meaningfully exercised outside of a real OS-managed background execution.
///
public protocol BackgroundTaskScheduler: Sendable { // sourcery: AutoMockable
    /// Cancels a previously scheduled request with the given identifier.
    ///
    /// - Parameter identifier: The identifier of the task request to cancel.
    ///
    func cancel(taskRequestWithIdentifier identifier: String)

    /// Registers a handler to be called when the system launches the task associated with the
    /// given identifier.
    ///
    /// - Parameters:
    ///   - identifier: The identifier for the task, as declared in the app's Info.plist under
    ///     `BGTaskSchedulerPermittedIdentifiers`.
    ///   - queue: The queue on which to call the launch handler. Pass `nil` to use a default
    ///     background queue.
    ///   - launchHandler: The handler called by the system when it launches the task.
    /// - Returns: `true` if registration succeeds, `false` otherwise.
    ///
    @discardableResult
    func register(
        forTaskWithIdentifier identifier: String,
        using queue: DispatchQueue?,
        launchHandler: @escaping (BGTask) -> Void,
    ) -> Bool

    /// Submits a request to schedule a background task.
    ///
    /// - Parameter taskRequest: The request describing the task to schedule.
    ///
    func submit(_ taskRequest: BGTaskRequest) throws
}
