import SwiftUI

// MARK: - IntroCarouselView

/// A view that allows the user to swipe through the intro carousel and then proceed to creating an
/// account or logging in.
///
struct IntroCarouselView: View {
    // MARK: Properties

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The `Store` for this view.
    @ObservedObject var store: Store<IntroCarouselState, IntroCarouselAction, Void>

    /// The index of the currently visible page in the carousel.
    @SwiftUI.State private var tabSelection = 0

    // MARK: View

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $tabSelection.animation()) {
                ForEachIndexed(store.state.pages) { index, page in
                    GeometryReader { reader in
                        dynamicStackView {
                            pageView(page)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, minHeight: reader.size.height)
                        .scrollView(addVerticalPadding: false)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEachIndexed(store.state.pages) { index, _ in
                    Image(systemName: "circle.fill")
                        .resizable()
                        .frame(width: 8, height: 8)
                        .foregroundStyle(
                            tabSelection == index ?
                                Asset.Colors.textPrimary.swiftUIColor :
                                Asset.Colors.textPrimary.swiftUIColor.opacity(0.3)
                        )
                }
            }
            .padding(16)

            VStack(spacing: 12) {
                Button(Localizations.createAccount) {
                    store.send(.createAccount)
                }
                .buttonStyle(.primary())

                Button(Localizations.logIn) {
                    store.send(.logIn)
                }
                .buttonStyle(.transparent)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility4)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
    }

    /// A dynamic stack view that lays out content vertically when in a regular vertical size class
    /// and horizontally for the compact vertical size class.
    @ViewBuilder
    private func dynamicStackView(@ViewBuilder _ content: () -> some View) -> some View {
        if verticalSizeClass == .regular {
            VStack(spacing: 80) {
                content()
            }
        } else {
            HStack(alignment: .top, spacing: 40) {
                content()
            }
        }
    }

    /// A view that displays a carousel page.
    @ViewBuilder
    private func pageView(_ page: IntroCarouselState.CarouselPage) -> some View {
        page.image
            .resizable()
            .frame(
                width: verticalSizeClass == .regular ? 200 : 132,
                height: verticalSizeClass == .regular ? 200 : 132
            )
            .accessibilityHidden(true)

        VStack(spacing: 16) {
            Text(page.title)
                .styleGuide(.title, weight: .bold)

            Text(page.message)
                .styleGuide(.title3)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Carousel") {
    IntroCarouselView(store: Store(processor: StateProcessor(state: IntroCarouselState())))
}

@available(iOS 17, *)
#Preview("Carousel Landscape", traits: .landscapeRight) {
    IntroCarouselView(store: Store(processor: StateProcessor(state: IntroCarouselState())))
}
#endif
