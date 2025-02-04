import SwiftUI
import SwiftUIIntrospect

// MARK: - EmailAccessView

/// A view that alerts the user to the new policy of sending emails to confirm new devices.
///
struct EmailAccessView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The `Store` for this view.
    @ObservedObject public var store: Store<EmailAccessState, EmailAccessAction, EmailAccessEffect>

    var body: some View {
        VStack(spacing: 24) {
            PageHeaderView(
                image: Asset.Images.Illustrations.businessWarning.swiftUIImage,
                style: .mediumImage,
                title: Localizations.importantNotice,
                message: Localizations.bitwardenWillSendACodeToYourAccountEmailDescriptionLong,
                accessory: Button {
                    store.send(.learnMoreTapped)
                } label: {
                    Text(Localizations.learnMore)
                        .styleGuide(.callout, weight: .semibold)
                        .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
                }
            )
            .padding(.top, 16)

            toggleCard

            AsyncButton(Localizations.continue) {
                await store.perform(.continueTapped)
            }
            .buttonStyle(.primary())
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .scrollView()
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .navigationBarHidden(true)
    }

    private var toggleCard: some View {
        ContentBlock {
            Text(LocalizedStringKey(Localizations.doYouHaveReliableAccessToYourEmail(
                store.state.emailAddress.withoutAutomaticEmailLinks()
            )))
            .styleGuide(.body)
            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
            .padding(16)

            Toggle(Localizations.yesICanReliablyAccessMyEmail, isOn: store.binding(
                get: \.canAccessEmail,
                send: EmailAccessAction.canAccessEmailChanged
            ))
            .toggleStyle(.bitwarden)
            .accessibilityIdentifier("AccessEmailToggle")
            .padding(16)
        }
        .multilineTextAlignment(.leading)
        .cornerRadius(10)
    }
}

// MARK: - EmailAccessView Previews

#if DEBUG
#Preview("Email Access") {
    NavigationView {
        EmailAccessView(
            store: Store(
                processor: StateProcessor(
                    state: EmailAccessState(
                        allowDelay: true,
                        emailAddress: "person@example.com"
                    )
                )
            )
        )
    }
}
#endif
