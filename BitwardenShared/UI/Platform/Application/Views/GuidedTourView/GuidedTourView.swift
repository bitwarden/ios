import SwiftUI

/// A view that displays dimmed background with a spotlight and a coach-mark card.
///
struct GuidedTourView: View {
    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The store for the guided tour view.
    @ObservedObject var store: Store<GuidedTourState, GuidedTourViewAction, Void>

    /// The height of the coach-mark card.
    @SwiftUI.State var cardHeight: CGFloat = 0

    /// The opacity of the guided tour view.
    @SwiftUI.State private var opacity: Double = 0.0

    /// The width of the coach-mark arrow.
    let arrowWidth: CGFloat = 47

    /// The height of the coach-mark arrow.
    let arrowHeight: CGFloat = 13

    /// The margin between the spotlight and the coach-mark.
    let spotLightAndCoachMarkMargin: CGFloat = 3

    /// The padding of the coach-mark card from the leading edge.
    var cardLeadingPadding: CGFloat {
        store.state.cardLeadingPadding ?? 0
    }

    /// The padding of the coach-mark card from the trailing edge.
    var cardTrailingPadding: CGFloat {
        store.state.cardTrailingPadding ?? 0
    }

    /// The width of the coach-mark card.
    var cardWidth: CGFloat {
        if verticalSizeClass == .compact {
            480
        } else {
            320
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                .mask(
                    Spotlight(
                        spotlight: store.state.spotlightRegion,
                        spotlightCornerRadius: store.state.spotlightCornerRadius,
                        spotlightShape: store.state.spotlightShape
                    )
                    .fill(style: FillStyle(eoFill: true))
                )

            VStack(alignment: .leading, spacing: 0) {
                let coachMarkVerticalPosition = calculateCoachMarkPosition()
                if coachMarkVerticalPosition == .bottom {
                    if store.state.arrowHorizontalPosition == .center {
                        Image(asset: Asset.Images.arrowUp)
                            .offset(x: calculateArrowHorizontalOffset())
                    }
                }
                VStack(alignment: .leading) {
                    cardContent()
                        .frame(width: cardWidth)
                        .onFrameChanged { _, size in
                            cardHeight = size.height
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: calculateCoachMarkCardHorizontalOffset())
                .padding(.leading, cardLeadingPadding)
                .padding(.trailing, cardTrailingPadding)

                if coachMarkVerticalPosition == .top {
                    if store.state.arrowHorizontalPosition == .center {
                        Image(asset: Asset.Images.arrowDown)
                            .offset(x: calculateArrowHorizontalOffset())
                    }
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
        .onAppear {
            withAnimation(.easeInOut(duration: UI.duration(0.3))) {
                opacity = 1
            }
        }
    }

    // MARK: - Private Methods

    /// Calculates the X offset of the coach-mark card.
    ///
    /// - Returns: The X offset value.
    ///
    private func calculateCoachMarkCardHorizontalOffset() -> CGFloat {
        let arrowOffset = calculateArrowHorizontalOffset()

        // if the card is too far from the coach mark arrow,
        // calculate the offset to show the card near the arrow.
        if cardLeadingPadding + cardWidth < arrowOffset + arrowWidth {
            return (arrowOffset + arrowWidth) - (cardLeadingPadding + cardWidth)
        }

        // if there is enough space to show the card as center of the arrow,
        // calculate the offset to show the card as center of the arrow.
        if UIScreen.main.bounds.width - arrowOffset + arrowWidth > cardWidth / 2,
           arrowOffset > cardWidth / 2 {
            return (arrowOffset + arrowWidth / 2 + cardWidth / 2) - (cardLeadingPadding + cardWidth)
        }
        return 0
    }

    /// Calculates the horizontal offset for centering the coach mark arrow.
    ///
    /// - Returns: The horizontal offset value.
    ///
    private func calculateArrowHorizontalOffset() -> CGFloat {
        store.state.spotlightRegion.origin.x
            + store.state.spotlightRegion.size.width / 2
            - (arrowWidth / 2)
    }

    /// Calculates the Y offset of the coach-mark card.
    ///
    /// - Returns: The Y offset value.
    ///
    private func calculateCoachMarkOffsetY() -> CGFloat {
        if calculateCoachMarkPosition() == .top {
            return store.state.spotlightRegion.origin.y
                - spotLightAndCoachMarkMargin
                - cardHeight
                - arrowHeight
        } else {
            return store.state.spotlightRegion.origin.y
                + store.state.spotlightRegion.size.height
                + spotLightAndCoachMarkMargin
        }
    }

    /// Calculates the vertical position of the coach-mark.
    ///
    /// - Returns: The vertical position of the coach-mark.
    ///
    private func calculateCoachMarkPosition() -> CoachMarkVerticalPosition {
        let topSpace = store.state.spotlightRegion.origin.y

        let bottomSpace = UIScreen.main.bounds.height
            - (
                store.state.spotlightRegion.origin.y
                    + store.state.spotlightRegion.size.height
            )

        if topSpace > bottomSpace {
            return .top
        } else {
            return .bottom
        }
    }

    /// The content of the coach-mark card.
    @ViewBuilder
    private func cardContent() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(store.state.progressText)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .styleGuide(.caption1, weight: .bold)

                Spacer()

                Button {
                    store.send(.dismissPressed)
                } label: {
                    Image(asset: Asset.Images.close16, label: Text(Localizations.dismiss))
                        .imageStyle(.accessoryIcon16(color: Asset.Colors.iconPrimary.swiftUIColor))
                }
            }

            Text(store.state.title)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .styleGuide(.body)

            HStack(spacing: 0) {
                if store.state.step > 1 {
                    Button {
                        store.send(.backPressed)
                    } label: {
                        Text(Localizations.back)
                            .styleGuide(.callout, weight: .semibold)
                            .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()
                    .frame(maxWidth: .infinity)

                Button {
                    if store.state.step < store.state.totalStep {
                        store.send(.nextPressed)
                    } else {
                        store.send(.donePressed)
                    }

                } label: {
                    Text(
                        store.state.step < store.state.totalStep ? Localizations.next : Localizations.done
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
