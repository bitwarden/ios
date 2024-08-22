import Foundation
import SwiftUI

// MARK: - LoadingState

/// An enumeration of the possible loading states for any screen with a loading state.
enum LoadingState<T: Equatable & Sendable>: Equatable, Sendable {
    /// The data that should be displayed on screen.
    case data(T)

    /// The view is loading.
    case loading(T?)

    /// The data to be displayed, if the case is `data`.
    var data: T? {
        switch self {
        case let .data(data):
            return data
        case let .loading(maybeData):
            return maybeData
        }
    }
}
