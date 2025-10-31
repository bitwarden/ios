import BitwardenKit
import SwiftUI

/// A scroll view that contains the guided tour content.
struct GuidedTourScrollView<Content: View>: View {
    /// The store for the guided tour view.
    @ObservedObject var store: Store<GuidedTourViewState, GuidedTourViewAction, Void>

    /// The content of the scroll view.
    @ViewBuilder var content: Content

    /// A state variable for disabling animations.
    @SwiftUI.State var disableAnimation = false

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The ID for scrolling to top of the view.
    let top = "top"

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                // Dummy spacer view for scroll view to locate when scrolling to top
                Spacer()
                    .frame(height: 0)
                    .id(top)

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
                transaction.disablesAnimations = disableAnimation
            }
            .onChange(of: verticalSizeClass) { _ in
                handleLandscapeScroll(reader)
            }
            .onChange(of: store.state.currentIndex) { _ in
                handleLandscapeScroll(reader)
            }
            .onChange(of: store.state.showGuidedTour) { newValue in
                if newValue {
                    disableAnimation = true
                } else {
                    reader.scrollTo(top)
                    // Need to reenable animation after dismissing the guided tour.
                    Task {
                        try? await Task.sleep(nanoseconds: 300 * NSEC_PER_MSEC)
                        disableAnimation = false
                    }
                }
            }
        }
    }

    /// A view that presents the guided tour.
    @ViewBuilder
    private func guidedTourView() -> some View {
        GuidedTourView(
            store: store,
        )
    }

    /// Scrolls to the guided tour step when in landscape mode.
    private func handleLandscapeScroll(_ reader: ScrollViewProxy) {
        reader.scrollTo(GuidedTourStep(rawValue: store.state.currentIndex))
    }
}
