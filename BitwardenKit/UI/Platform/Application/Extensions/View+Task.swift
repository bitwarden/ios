import SwiftUI

/// A `ViewModifier` that debounces an async action and restarts it when a tracked value changes,
/// without using `.task(id:)` — which triggers a linker error at iOS 15 deployment target when
/// built against the iOS 26 SDK because of a new `@isolated(any)` overload in SwiftUICore.
private struct DebouncedTaskModifier<T: Equatable>: ViewModifier {
    /// The value to observe for changes; triggers a task restart when it changes.
    let id: T

    /// The minimum quiet interval (in nanoseconds) that must elapse before the action fires.
    let debounceIntervalInNS: UInt64

    /// The async action to execute after the debounce interval elapses.
    let action: @Sendable () async -> Void

    /// The currently running debounced task, cancelled and replaced on each restart.
    @SwiftUI.State private var currentTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onAppear { restart() }
            .onChange(of: id) { _ in restart() }
            .onDisappear {
                currentTask?.cancel()
                currentTask = nil
            }
    }

    private func restart() {
        currentTask?.cancel()
        let interval = debounceIntervalInNS
        let work = action
        currentTask = Task {
            try? await Task.sleep(nanoseconds: interval)
            guard !Task.isCancelled else { return }
            await work()
        }
    }
}

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
    nonisolated func debouncedTask<T>(
        id value: T,
        debounceIntervalInNS: UInt64,
        _ action: @escaping @Sendable () async -> Void,
    ) -> some View where T: Equatable {
        modifier(DebouncedTaskModifier(id: value, debounceIntervalInNS: debounceIntervalInNS, action: action))
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
