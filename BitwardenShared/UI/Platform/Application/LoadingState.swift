import Foundation
import SwiftUI

// MARK: - LoadingState

/// An enumeration of the possible loading states for any screen with a loading state.
enum LoadingState<T: Equatable & Sendable>: Equatable, Sendable {
    /// The data that should be displayed on screen.
    case data(T)

    /// The view is loading.
    case loading(T?)

    /// An error occurred while loading the data.
    case error(errorMessage: String)

    /// The data to be displayed, if the case is `data`.
    var data: T? {
        switch self {
        case let .data(data):
            data
        case let .loading(maybeData):
            maybeData
        case .error:
            nil
        }
    }

    /// Whether the loading state is currently in the loading state.
    ///
    /// - Returns: `true` if the case is `.loading`, `false` otherwise.
    ///
    var isLoading: Bool {
        switch self {
        case .data,
             .error:
            false
        case .loading:
            true
        }
    }
}
