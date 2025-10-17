import BitwardenKit
import SwiftUI

// MARK: - LoadingView

/// A view that displays either a loading indicator or the content view for a set of loaded data.
struct LoadingView<T: Equatable & Sendable, Contents: View, ErrorView: View>: View {
    /// The state of this view.
    var state: LoadingState<T>

    /// A view builder for displaying the loaded contents of this view.
    @ViewBuilder var contents: (T) -> Contents

    /// A view builder for displaying the error view with an error message.
    @ViewBuilder var errorView: (String) -> ErrorView

    var body: some View {
        switch state {
        case .loading:
            CircularActivityIndicator()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .data(data):
            contents(data)
        case let .error(errorMessage):
            errorView(errorMessage)
        }
    }

    /// Custom initializer for when ErrorView is EmptyView
    ///
    /// - Parameters:
    ///   - state: The state of this view.
    ///   - contents: A view builder for displaying the loaded contents of this view.
    ///
    init(
        state: LoadingState<T>,
        @ViewBuilder contents: @escaping (T) -> Contents,
    ) where ErrorView == EmptyView {
        self.state = state
        self.contents = contents
        errorView = { _ in EmptyView() }
    }

    /// Default initializer
    ///
    /// - Parameters:
    ///   - state: The state of this view.
    ///   - contents: A view builder for displaying the loaded contents of this view.
    ///   - error: A view builder for displaying the error view with an error message.
    ///
    init(
        state: LoadingState<T>,
        @ViewBuilder contents: @escaping (T) -> Contents,
        @ViewBuilder errorView: @escaping (String) -> ErrorView,
    ) {
        self.state = state
        self.contents = contents
        self.errorView = errorView
    }
}
