import SwiftUI

/// A scroll view that contains the guided tour content.
struct GuidedTourScrollView<Content: View>: View {
    /// The store for the guided tour view.
    @ObservedObject var store: Store<GuidedTourViewState, GuidedTourViewAction, Void>
    
    /// The content of the scroll view.
    @ViewBuilder var content: Content

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                // Dummy spacer view for scroll view to locate when scrolling to top
                Spacer()
                    .frame(height: 0)
                    .id(Constants.top)

                content
            }
            .fullScreenCover(isPresented: store.binding(get: { state in
                state.showGuidedTour
            }, send: { state in
                .toggleGuidedTourVisibilityChanged(state)
            })) {
                guidedTourView()
            }
            .transaction { transaction in
                // disable the default FullScreenCover modal animation
                transaction.disablesAnimations = true
            }
            .onChange(of: verticalSizeClass) { _ in
                handleLandscapeScroll(reader)
            }
            .onChange(of: store.state.currentIndex) { _ in
                handleLandscapeScroll(reader)
            }
            .onChange(of: store.state.showGuidedTour) { newValue in
                if newValue == false {
                    reader.scrollTo(Constants.top)
                }
            }
        }
    }

    /// A view that presents the guided tour.
    @ViewBuilder
    private func guidedTourView() -> some View {
        GuidedTourView(
            store: store
        )
    }

    /// Scrolls to the guided tour step when in landscape mode.
    private func handleLandscapeScroll(_ reader: ScrollViewProxy) {
        reader.scrollTo(GuidedTourStep(rawValue: store.state.currentIndex))
    }
}
