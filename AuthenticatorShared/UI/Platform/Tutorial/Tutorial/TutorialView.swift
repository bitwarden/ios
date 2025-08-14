import BitwardenResources
import SwiftUI

// MARK: - TutorialView

/// A view containing the tutorial screens
///
struct TutorialView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<TutorialState, TutorialAction, TutorialEffect>

    /// The vertical size class to determine if we're in landscape mode.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // MARK: View

    var body: some View {
        content
            .navigationBar(title: Localizations.bitwardenAuthenticator, titleDisplayMode: .inline)
    }

    // MARK: Private Properties

    private var content: some View {
        VStack(spacing: 24) {
            if verticalSizeClass == .regular {
                Spacer()
            }
            TabView(
                selection: store.binding(
                    get: \.page,
                    send: TutorialAction.pageChanged
                )
            ) {
                slide(
                    image: Asset.Images.recoveryCodesBig,
                    titleText: Localizations.secureYourAssetsWithBitwardenAuthenticator,
                    bodyText: Localizations.getVerificationCodesForAllYourAccounts
                ).tag(TutorialPage.intro)

                slide(
                    image: Asset.Images.qrIllustration,
                    titleText: Localizations.useYourDeviceCameraToScanCodes,
                    bodyText: Localizations.scanTheQRCodeInYourSettings
                ).tag(TutorialPage.qrScanner)

                slide(
                    image: Asset.Images.verificationCode,
                    titleText: Localizations.signInUsingUniqueCodes,
                    bodyText: Localizations.whenUsingTwoStepVerification
                ).tag(TutorialPage.uniqueCodes)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding(.top, 16)
            .animation(.default, value: store.state.page)
            .transition(.slide)

            Button(store.state.continueButtonText) {
                store.send(.continueTapped)
            }
            .buttonStyle(.primary())

            Button {
                store.send(.skipTapped)
            } label: {
                Text(Localizations.skip)
                    .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
            }
            .buttonStyle(InlineButtonStyle())
            .hidden(store.state.isLastPage)
        }
        .padding(16)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
    }

    @ViewBuilder
    private func slide(image: ImageAsset, titleText: String, bodyText: String) -> some View {
        if verticalSizeClass == .regular {
            VStack(spacing: 24) {
                Image(decorative: image)
                    .frame(height: 146)

                Text(titleText)
                    .styleGuide(.title2)

                Text(bodyText)

                Spacer()
            }
            .multilineTextAlignment(.center)
            .scrollView()
        } else {
            HStack(alignment: .top, spacing: 24) {
                Image(decorative: image)
                    .frame(height: 146)

                VStack(alignment: .leading, spacing: 24) {
                    Text(titleText)
                        .styleGuide(.title2)

                    Text(bodyText)

                    Spacer()
                }
                .scrollView()
            }
        }
    }
}

#if DEBUG
struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TutorialView(
                store: Store(
                    processor: StateProcessor(
                        state: TutorialState(page: .intro)
                    )
                )
            )
        }.previewDisplayName("Intro")

        NavigationView {
            TutorialView(
                store: Store(
                    processor: StateProcessor(
                        state: TutorialState(page: .qrScanner)
                    )
                )
            )
        }.previewDisplayName("QR Scanner")

        NavigationView {
            TutorialView(
                store: Store(
                    processor: StateProcessor(
                        state: TutorialState(page: .uniqueCodes)
                    )
                )
            )
        }.previewDisplayName("Unique Codes")
    }
}
#endif
