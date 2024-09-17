import SwiftUI

// MARK: - LoadingView

/// A view that displays either a loading indicator or the content view for a set of loaded data.
struct LoadingView<T: Equatable & Sendable, Contents: View>: View {
    /// The state of this view.
    var state: LoadingState<T>

    /// A view builder for displaying the loaded contents of this view.
    @ViewBuilder var contents: (T) -> Contents

    var body: some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .data(data):
            contents(data)
        }
    }
}
