import SwiftUI

// MARK: - TutorialView

/// A view containing the tutorial screens
///
struct TutorialView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<TutorialState, TutorialAction, TutorialEffect>

    // MARK: View

    var body: some View {
        content
            .navigationBar(title: Localizations.bitwardenAuthenticator, titleDisplayMode: .inline)
    }

    // MARK: Private Properties

    private var content: some View {
        VStack(spacing: 24) {
            Spacer()
            TabView(
                selection: store.binding(
                    get: \.page,
                    send: TutorialAction.pageChanged
                )
            ) {
                intoSlide.tag(TutorialPage.intro)
                qrScannerSlide.tag(TutorialPage.qrScanner)
                uniqueCodesSlide.tag(TutorialPage.uniqueCodes)
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

    private var intoSlide: some View {
        VStack(spacing: 24) {
            Asset.Images.recoveryCodes.swiftUIImage
                .frame(height: 140)

            Text(Localizations.secureYourAssetsWithBitwardenAuthenticator)
                .styleGuide(.title2)

            Text(Localizations.getVerificationCodesForAllYourAccounts)

            Spacer()
        }
        .multilineTextAlignment(.center)
    }

    private var qrScannerSlide: some View {
        VStack(spacing: 24) {
            Asset.Images.qrIllustration.swiftUIImage
                .frame(height: 140)

            Text(Localizations.useYourDeviceCameraToScanCodes)
                .styleGuide(.title2)

            Text(Localizations.scanTheQRCodeInYourSettings)

            Spacer()
        }
        .multilineTextAlignment(.center)
    }

    private var uniqueCodesSlide: some View {
        VStack(spacing: 24) {
            Asset.Images.uniqueCodes.swiftUIImage
                .frame(height: 140)

            Text(Localizations.signInUsingUniqueCodes)
                .styleGuide(.title2)

            Text(Localizations.whenUsingTwoStepVerification)

            Spacer()
        }
        .multilineTextAlignment(.center)
    }
}

#Preview("Tutorial") {
    NavigationView {
        TutorialView(
            store: Store(
                processor: StateProcessor(
                    state: TutorialState()
                )
            )
        )
    }
}
