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

    /// The opacity of the guided tour view.
    @SwiftUI.State private var opacity: Double = 0.0

    /// The size of the view.
    @SwiftUI.State private var viewSize: CGSize = .zero

    /// The size of the coach-mark arrow icon.
    let arrowSize = CGSize(width: 47, height: 13)

    /// The margin between the spotlight and the coach-mark.
    let spotLightAndCoachMarkMargin: CGFloat = 3

    /// The padding of the coach-mark card from the leading edge.
    var cardLeadingPadding: CGFloat {
        store.state.currentStepState.cardLeadingPadding
    }

    /// The padding of the coach-mark card from the trailing edge.
    var cardTrailingPadding: CGFloat {
        store.state.currentStepState.cardTrailingPadding
    }

    /// The max width of the coach-mark card.
    var cardMaxWidth: CGFloat {
        if verticalSizeClass == .compact {
            480
        } else {
            320
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    .mask(
                        Spotlight(
                            spotlight: store.state.currentStepState.spotlightRegion,
                            spotlightCornerRadius: store.state.currentStepState.spotlightCornerRadius,
                            spotlightShape: store.state.currentStepState.spotlightShape
                        )
                        .fill(style: FillStyle(eoFill: true))
                    )

                VStack(alignment: .leading, spacing: 0) {
                    let coachMarkVerticalPosition = calculateCoachMarkPosition()
                    if coachMarkVerticalPosition == .bottom {
                        Image(asset: Asset.Images.arrowUp)
                            .offset(x: calculateArrowHorizontalOffset())
                    }
                    VStack(alignment: .leading) {
                        cardContent()
                            .frame(maxWidth: cardMaxWidth)
                            .onFrameChanged { _, size in
                                cardSize = size
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: calculateCoachMarkCardHorizontalOffset())
                    .padding(.leading, cardLeadingPadding)
                    .padding(.trailing, cardTrailingPadding)

                    if coachMarkVerticalPosition == .top {
                        Image(asset: Asset.Images.arrowDown)
                            .offset(x: calculateArrowHorizontalOffset())
                    }
                }
                .padding(0)
                .frame(maxWidth: .infinity)
                .offset(y: calculateCoachMarkOffsetY())
            }
            .opacity(opacity)
            .ignoresSafeArea(.all)
            .background(FullScreenCoverBackgroundRemovalView())
            .transition(.opacity)
            .task(id: verticalSizeClass) {
                viewSize = geometry.size
            }
            .onAppear {
                withAnimation(.easeInOut(duration: UI.duration(0.3))) {
                    opacity = 1
                }
                viewSize = geometry.size
            }
        }
    }

    // MARK: - Private Methods

    /// The content of the coach-mark card.
    @ViewBuilder
    private func cardContent() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text(store.state.progressText)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .styleGuide(.caption1, weight: .bold)

                Spacer()

                Button {
                    store.send(.dismissTapped)
                } label: {
                    Image(asset: Asset.Images.close16, label: Text(Localizations.dismiss))
                        .imageStyle(.accessoryIcon16(color: Asset.Colors.iconPrimary.swiftUIColor))
                }
            }

            Text(store.state.currentStepState.title)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .styleGuide(.body)

            HStack(spacing: 0) {
                if store.state.step > 1 {
                    Button {
                        store.send(.backTapped)
                    } label: {
                        Text(Localizations.back)
                            .styleGuide(.callout, weight: .semibold)
                            .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
                            .multilineTextAlignment(.leading)
                    }
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
                    .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
                    .multilineTextAlignment(.leading)
                }
            }
            .padding(0)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension GuidedTourView {
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
        if viewSize.width - arrowOffset + arrowSize.width > cardSize.width / 2,
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
            return store.state.currentStepState.spotlightRegion.origin.y
                - spotLightAndCoachMarkMargin
                - cardSize.height
                - arrowSize.height
        } else {
            return store.state.currentStepState.spotlightRegion.origin.y
                + store.state.currentStepState.spotlightRegion.size.height
                + spotLightAndCoachMarkMargin
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
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
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
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .ignoresSafeArea()
        }
        .previewDisplayName("Rectangle")
    }
}
#endif
