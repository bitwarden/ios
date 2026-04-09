import SwiftUI

public extension View {
    /// Adds a debounced task to perform before this view appears or when a specified
    /// value changes.
    /// This means that the task will execute the action when the specified value doesn't change
    /// in the debounce interval specified.
    ///
    /// - Parameters:
    ///   - id: The value to observe for changes. The value must conform
    ///     to the <doc://com.apple.documentation/documentation/Swift/Equatable>
    ///     protocol.
    ///   - debounceIntervalInNS: The interval to be set for debouncing the task.
    ///   - action: A closure that SwiftUI calls as an asynchronous task
    ///     before the view appears. SwiftUI can automatically cancel the task
    ///     after the view disappears before the action completes. If the
    ///     `id` value changes, SwiftUI cancels and restarts the task.
    ///
    /// - Returns: A view that runs the specified action asynchronously before
    ///   the view appears, or restarts the task when the `id` value changes.
    @inlinable
    nonisolated func debouncedTask<T>(
        id value: T,
        debounceIntervalInNS: UInt64,
        _ action: @escaping @Sendable () async -> Void,
    ) -> some View where T: Equatable {
        task(id: value) {
            try? await Task.sleep(nanoseconds: debounceIntervalInNS)
            guard !Task.isCancelled else {
                return
            }
            await action()
        }
    }

    /// Adds a task to perform before this view appears or when a specified
    /// value changes to be used on debounced searches.
    ///
    /// - Parameters:
    ///   - id: The value to observe for changes. The value must conform
    ///     to the <doc://com.apple.documentation/documentation/Swift/Equatable>
    ///     protocol.
    ///   - action: A closure that SwiftUI calls as an asynchronous task
    ///     before the view appears. SwiftUI can automatically cancel the task
    ///     after the view disappears before the action completes. If the
    ///     `id` value changes, SwiftUI cancels and restarts the task.
    ///
    /// - Returns: A view that runs the specified action asynchronously before
    ///   the view appears, or restarts the task when the `id` value changes.
    @inlinable
    nonisolated func searchDebouncedTask<T>(
        id value: T,
        _ action: @escaping @Sendable () async -> Void,
    ) -> some View where T: Equatable {
        debouncedTask(
            id: value,
            debounceIntervalInNS: Constants.searchDebounceTimeInNS,
            action,
        )
    }
}
