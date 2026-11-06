import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - LoadingView

/// A view that displays either a loading indicator or the content view for a set of loaded data.
struct LoadingView<T: Equatable & Sendable, Contents: View, ErrorView: View>: View {
    /// A view builder for displaying the loaded contents of this view.
    @ViewBuilder var contents: (T) -> Contents

    /// A view builder for displaying the error view with an error message.
    @ViewBuilder var errorView: (String) -> ErrorView

    /// An optional message displayed below the loading indicator while in the loading state.
    var loadingMessage: String?

    /// The state of this view.
    var state: LoadingState<T>

    var body: some View {
        switch state {
        case .loading:
            VStack(spacing: 24) {
                CircularActivityIndicator()
                if let loadingMessage {
                    Text(loadingMessage)
                        .styleGuide(.headline, weight: .semibold)
                        .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .data(data):
            contents(data)
        case let .error(errorMessage):
            errorView(errorMessage)
        }
    }

    /// Initializer that shows nothing for the error state.
    ///
    /// - Parameters:
    ///   - state: The state of this view.
    ///   - loadingMessage: An optional message to display below the loading indicator.
    ///   - contents: A view builder for displaying the loaded contents of this view.
    ///
    init(
        state: LoadingState<T>,
        loadingMessage: String? = nil,
        @ViewBuilder contents: @escaping (T) -> Contents,
    ) where ErrorView == EmptyView {
        self.state = state
        self.loadingMessage = loadingMessage
        self.contents = contents
        errorView = { _ in EmptyView() }
    }

    /// Initializer for when both a content view and an error view are needed.
    ///
    /// - Parameters:
    ///   - state: The state of this view.
    ///   - loadingMessage: An optional message to display below the loading indicator.
    ///   - contents: A view builder for displaying the loaded contents of this view.
    ///   - errorView: A view builder for displaying the error view with an error message.
    ///
    init(
        state: LoadingState<T>,
        loadingMessage: String? = nil,
        @ViewBuilder contents: @escaping (T) -> Contents,
        @ViewBuilder errorView: @escaping (String) -> ErrorView,
    ) {
        self.state = state
        self.loadingMessage = loadingMessage
        self.contents = contents
        self.errorView = errorView
    }
}
