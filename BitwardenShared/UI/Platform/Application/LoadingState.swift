import Foundation
import SwiftUI

// MARK: - LoadingState

/// An enumeration of the possible loading states for any screen with a loading state.
enum LoadingState<T: Equatable>: Equatable {
    /// The data that should be displayed on screen.
    case data(T)

    /// The view is loading.
    case loading

    /// The data to be displayed, if the case is `data`.
    var data: T? {
        guard case let .data(data) = self else { return nil }
        return data
    }
}
