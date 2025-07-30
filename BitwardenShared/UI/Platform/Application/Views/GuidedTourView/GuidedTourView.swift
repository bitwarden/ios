import BitwardenResources
import SwiftUI

/// A view that displays dimmed background with a spotlight and a coach-mark card.
///
struct GuidedTourView: View {
    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The store for the guided tour view.
    @ObservedObject var store: Store<GuidedTourViewState, GuidedTourViewAction, Void>

    // MARK: Private Properties

    /// The actual size of the coach-mark card.
    @SwiftUI.State private var cardSize: CGSize = .zero

    /// A flag to control the initial visibility and position of the arrow.
    @SwiftUI.State private var isArrowVisible = false

    /// A flag to control the initial visibility and position of the card.
    @SwiftUI.State private var isCardVisible = false

    /// The size of the view.
    @SwiftUI.State private var viewSize: CGSize = .zero

    /// The animation duration for the coach-mark view.
    private let animationDuration = UI.duration(0.3)

    /// The size of the coach-mark arrow icon.
    private let arrowSize = CGSize(width: 47, height: 13)

    /// The padding of the coach-mark card from the leading edge.
    private var cardLeadingPadding: CGFloat {
        store.state.currentStepState.cardLeadingPadding
    }

    /// The padding of the coach-mark card from the trailing edge.
    private var cardTrailingPadding: CGFloat {
        store.state.currentStepState.cardTrailingPadding
    }

    /// The max width of the coach-mark card.
    private var cardMaxWidth: CGFloat {
        verticalSizeClass == .compact ? 480 : 320
    }

    /// The maximum dynamic type size for the view Default is `.xxLarge`
    private let maxDynamicTypeSize: DynamicTypeSize = .xxxLarge

    /// The margin between the spotlight and the coach-mark.
    private let spotlightAndCoachMarkMargin: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                dimmedBackground
                    .mask(spotlightMask)

                arrowView

                cardView(geometry: geometry)
            }
            .padding(0)
            .opacity(isCardVisible ? 1 : 0)
            .ignoresSafeArea(.all)
            .background(FullScreenCoverBackgroundRemovalView())
            .transition(.opacity)
            .task(id: verticalSizeClass) {
                viewSize = geometry.size
            }
            .onAppear {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    isCardVisible = true
                }
                viewSize = geometry.size

                withAnimation(.easeInOut(duration: animationDuration).delay(animationDuration)) {
                    isArrowVisible = true
                }
            }
        }
    }

    /// The arrow view of the coach-mark.
    @ViewBuilder private var arrowView: some View {
        let coachMarkVerticalPosition = calculateCoachMarkPosition()
        let shouldRotateArrow = coachMarkVerticalPosition == .top
        Image(asset: Asset.Images.arrowUp)
            .opacity(isArrowVisible ? 1 : 0)
            .rotationEffect(.degrees(shouldRotateArrow ? 180 : 0))
            .animation(.smooth(duration: animationDuration), value: shouldRotateArrow)
            .position(
                x: calculateArrowAbsoluteXPosition(),
                y: isArrowVisible
                    ? calculateArrowAbsoluteYPosition()
                    : (shouldRotateArrow
                        ? calculateArrowAbsoluteYPosition() - arrowSize.height
                        : calculateArrowAbsoluteYPosition() + arrowSize.height)
            )
            .smoothTransition(animation: .smooth(duration: animationDuration), value: store.state.currentIndex)
    }

    /// The dimmed background of the coach-mark view.
    private var dimmedBackground: some View {
        Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
    }

    /// The spotlight mask of the coach-mark view.
    private var spotlightMask: some View {
        Spotlight(
            spotlight: store.state.currentStepState.spotlightRegion,
            spotlightShape: store.state.currentStepState.spotlightShape
        )
        .fill(style: FillStyle(eoFill: true))
    }

    // MARK: - Private Methods

    /// The content of the coach-mark card.
    @ViewBuilder
    private func cardContent() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text(store.state.progressText)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .styleGuide(.caption1, weight: .bold)
                    .dynamicTypeSize(...maxDynamicTypeSize)
                    .smoothTransition(
                        animation: .smooth(duration: animationDuration),
                        value: store.state.currentStepState
                    )

                Spacer()

                Button {
                    store.send(.dismissTapped)
                } label: {
                    Image(asset: Asset.Images.close16, label: Text(Localizations.dismiss))
                        .imageStyle(.accessoryIcon16(color: SharedAsset.Colors.iconPrimary.swiftUIColor))
                }
            }

            Text(store.state.currentStepState.title)
                .dynamicTypeSize(...maxDynamicTypeSize)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .styleGuide(.body)
                .smoothTransition(
                    animation: .smooth(duration: animationDuration),
                    value: store.state.currentStepState
                )

            cardNavigationButtons()
        }
        .padding(16)
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// The navigation `Next` and `Back` buttons of the coach-mark card.
    @ViewBuilder
    private func cardNavigationButtons() -> some View {
        HStack(spacing: 0) {
            if store.state.step > 1 {
                Button {
                    store.send(.backTapped)
                } label: {
                    Text(Localizations.back)
                        .styleGuide(.callout, weight: .semibold)
                        .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .dynamicTypeSize(...maxDynamicTypeSize)
                }
                .smoothTransition(
                    animation: .smooth(duration: animationDuration),
                    value: store.state.currentStepState
                )
            }

            Spacer()

            Button {
                if store.state.step < store.state.totalSteps {
                    store.send(.nextTapped)
                } else {
                    store.send(.doneTapped)
                }

            } label: {
                Text(
                    store.state.step < store.state.totalSteps ? Localizations.next : Localizations.done
                )
                .styleGuide(.callout, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
                .multilineTextAlignment(.leading)
                .dynamicTypeSize(...maxDynamicTypeSize)
            }
            .smoothTransition(
                animation: .smooth(duration: animationDuration),
                value: store.state.currentStepState
            )
        }
        .padding(0)
        .frame(maxWidth: .infinity)
    }

    /// The card view of the coach-mark.
    @ViewBuilder
    private func cardView(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if calculateCoachMarkPosition() == .bottom {
                Spacer().frame(height: arrowSize.height)
            }

            VStack(alignment: .leading) {
                cardContent()
                    .frame(maxWidth: cardMaxWidth)
                    .onFrameChanged(id: "card") { _, size in
                        withAnimation(.smooth(duration: animationDuration)) {
                            cardSize = size
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: isCardVisible ? calculateCoachMarkCardHorizontalOffset() : 25)
            .padding(.leading, cardLeadingPadding)
            .padding(.trailing, cardTrailingPadding)
            .smoothTransition(
                animation: .smooth(duration: animationDuration),
                value: store.state.currentStepState
            )

            if calculateCoachMarkPosition() == .top {
                Spacer().frame(height: arrowSize.height)
            }
        }
        .padding(0)
        .frame(maxWidth: .infinity)
        .offset(y: isCardVisible ? calculateCoachMarkOffsetY() : geometry.size.height)
        .opacity(isCardVisible ? 1 : 0)
        .smoothTransition(
            animation: .smooth(duration: animationDuration),
            value: store.state.currentStepState
        )
    }
}

extension GuidedTourView {
    /// Calculates the absolute X position of the coach-mark arrow.
    ///
    /// - Returns: The absolute X position of the coach-mark arrow.
    ///
    private func calculateArrowAbsoluteXPosition() -> CGFloat {
        calculateArrowHorizontalOffset() + cardLeadingPadding
    }

    /// Calculates the absolute Y position of the coach-mark arrow.
    ///
    /// - Returns: The absolute Y position of the coach-mark arrow.
    ///
    private func calculateArrowAbsoluteYPosition() -> CGFloat {
        let coachMarkVerticalPosition = calculateCoachMarkPosition()
        if coachMarkVerticalPosition == .bottom {
            return store.state.currentStepState.spotlightRegion.origin.y
                + spotlightAndCoachMarkMargin
                + store.state.currentStepState.spotlightRegion.size.height
                + arrowSize.height / 2
        } else {
            return store.state.currentStepState.spotlightRegion.origin.y
                - spotlightAndCoachMarkMargin
                - arrowSize.height / 2
        }
    }

    /// Calculates the X offset of the coach-mark card.
    ///
    /// - Returns: The X offset value.
    ///
    private func calculateCoachMarkCardHorizontalOffset() -> CGFloat {
        let arrowOffset = calculateArrowHorizontalOffset()

        // If the card is too far from the coach mark arrow,
        // calculate the offset to show the card near the arrow.
        if cardLeadingPadding + cardSize.width < arrowOffset + arrowSize.width {
            return (arrowOffset + arrowSize.width) - (cardLeadingPadding + cardSize.width)
        }

        // If there is enough space to show the card as center of the arrow,
        // calculate the offset to show the card as center of the arrow.
        if viewSize.width - arrowOffset + arrowSize.width / 2 > cardSize.width / 2,
           arrowOffset > cardSize.width / 2 {
            return (arrowOffset + arrowSize.width / 2 + cardSize.width / 2)
                - (cardLeadingPadding + cardSize.width)
        }
        return 0
    }

    /// Calculates the horizontal offset of the coach-mark arrow.
    ///
    /// - Returns: The horizontal offset value.
    ///
    private func calculateArrowHorizontalOffset() -> CGFloat {
        switch store.state.currentStepState.arrowHorizontalPosition {
        case .left:
            calculateArrowHorizontalOffsetForLeft()
        case .center:
            calculateArrowHorizontalOffsetForCenter()
        case .right:
            calculateArrowHorizontalOffsetForRight()
        }
    }

    /// Calculates the horizontal offset for centering the coach mark arrow.
    ///
    /// - Returns: The horizontal offset value.
    ///
    private func calculateArrowHorizontalOffsetForCenter() -> CGFloat {
        store.state.currentStepState.spotlightRegion.origin.x
            + store.state.currentStepState.spotlightRegion.size.width / 2
            - (arrowSize.width / 2)
    }

    /// Calculates the horizontal offset for positioning the coach mark arrow when the arrow is on the left.
    ///
    /// - Returns: The horizontal offset value.
    ///
    private func calculateArrowHorizontalOffsetForLeft() -> CGFloat {
        let result = store.state.currentStepState.spotlightRegion.origin.x
            + (store.state.currentStepState.spotlightRegion.size.width / 3) / 2
            - (arrowSize.width / 2)
        return result
    }

    /// Calculates the horizontal offset for positioning the coach mark arrow when the arrow is on the right.
    ///
    /// - Returns: The horizontal offset value.
    ///
    private func calculateArrowHorizontalOffsetForRight() -> CGFloat {
        let result = store.state.currentStepState.spotlightRegion.origin.x
            + store.state.currentStepState.spotlightRegion.size.width
            - (store.state.currentStepState.spotlightRegion.size.width / 3) / 2
            - (arrowSize.width / 2)
        return result
    }

    /// Calculates the Y offset of the coach-mark card.
    ///
    /// - Returns: The Y offset value.
    ///
    private func calculateCoachMarkOffsetY() -> CGFloat {
        if calculateCoachMarkPosition() == .top {
            store.state.currentStepState.spotlightRegion.origin.y
                - spotlightAndCoachMarkMargin
                - cardSize.height
                - arrowSize.height
        } else {
            store.state.currentStepState.spotlightRegion.origin.y
                + store.state.currentStepState.spotlightRegion.size.height
                + spotlightAndCoachMarkMargin
        }
    }

    /// Calculates the vertical position of the coach-mark.
    ///
    /// - Returns: The vertical position of the coach-mark.
    ///
    private func calculateCoachMarkPosition() -> CoachMarkVerticalPosition {
        let topSpace = store.state.currentStepState.spotlightRegion.origin.y

        let bottomSpace = viewSize.height
            - (
                store.state.currentStepState.spotlightRegion.origin.y
                    + store.state.currentStepState.spotlightRegion.size.height
            )

        if topSpace > bottomSpace {
            return .top
        } else {
            return .bottom
        }
    }
}

// MARK: Previews

#if DEBUG
struct GuidedTourView_Previews: PreviewProvider {
    static let loginStep1: GuidedTourStepState = {
        var step = GuidedTourStepState.loginStep1
        step.spotlightRegion = CGRect(x: 338, y: 120, width: 40, height: 40)
        return step

    }()

    static let loginStep2: GuidedTourStepState = {
        var step = GuidedTourStepState.loginStep2
        step.spotlightRegion = CGRect(x: 10, y: 185, width: 380, height: 94)
        return step

    }()

    static let guidedTourViewState: GuidedTourViewState = {
        var state = GuidedTourViewState(guidedTourStepStates: [loginStep1, loginStep2])
        state.currentIndex = 1
        return state
    }()

    static let loginItemView = AddEditLoginItemView(
        store: Store(
            processor: StateProcessor(
                state: LoginItemState(
                    isTOTPAvailable: false,
                    totpState: .none
                )
            )
        )
    )

    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    loginItemView
                }
                .padding(16)
            }
            .fullScreenCover(isPresented: .constant(true)) {
                GuidedTourView(
                    store: Store(
                        processor: StateProcessor(
                            state: GuidedTourViewState(guidedTourStepStates: [loginStep1, loginStep2])
                        )
                    )
                )
            }
            .transaction { transaction in
                // disable the default FullScreenCover modal animation
                transaction.disablesAnimations = true
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .ignoresSafeArea()
        }
        .previewDisplayName("Circle")

        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    loginItemView
                }
                .padding(16)
            }
            .fullScreenCover(isPresented: .constant(true)) {
                GuidedTourView(
                    store: Store(
                        processor: StateProcessor(
                            state: guidedTourViewState
                        )
                    )
                )
            }
            .transaction { transaction in
                // disable the default FullScreenCover modal animation
                transaction.disablesAnimations = true
            }
            .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
            .ignoresSafeArea()
        }
        .previewDisplayName("Rectangle")
    }
}
#endif // swiftlint:disable:this file_length
