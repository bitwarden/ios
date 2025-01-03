import SwiftUI

// MARK: - SetUpTwoFactorView

/// A view that alerts the user to the new policy of sending emails to confirm new devices.
///
struct SetUpTwoFactorView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    /// The `Store` for this view.
    @ObservedObject public var store: Store<SetUpTwoFactorState, SetUpTwoFactorAction, SetUpTwoFactorEffect>

    var body: some View {
        VStack(spacing: 24) {
            PageHeaderView(
                image: Asset.Images.Illustrations.userLock.swiftUIImage,
                style: .mediumImage,
                title: Localizations.setUpTwoStepLogin,
                message: Localizations.youCanSetUpTwoStepLoginAsAnAlternativeDescriptionLong
            )
            .padding(.top, 16)

            Button {
                store.send(.turnOnTwoFactorTapped)
            } label: {
                Label {
                    Text(Localizations.turnOnTwoStepLogin)
                } icon: {
                    Asset.Images.externalLink24.swiftUIImage
                }
            }
            .buttonStyle(.primary())

            Button {
                store.send(.changeAccountEmailTapped)
            } label: {
                Label {
                    Text(Localizations.changeAccountEmail)
                } icon: {
                    Asset.Images.externalLink24.swiftUIImage
                }
            }
            .buttonStyle(.secondary())

            if store.state.allowDelay {
                AsyncButton(Localizations.remindMeLater) {
                    await store.perform(.remindMeLaterTapped)
                }
                .buttonStyle(.secondary())
            }
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
    }
}

// MARK: - SetUpTwoFactorView Previews

#if DEBUG
#Preview("Allowing Delay") {
    NavigationView {
        SetUpTwoFactorView(
            store: Store(
                processor: StateProcessor(
                    state: SetUpTwoFactorState(
                        allowDelay: true,
                        emailAddress: ""
                    )
                )
            )
        )
    }
}

#Preview("Not Allowing Delay") {
    NavigationView {
        SetUpTwoFactorView(
            store: Store(
                processor: StateProcessor(
                    state: SetUpTwoFactorState(
                        allowDelay: false,
                        emailAddress: ""
                    )
                )
            )
        )
    }
}
#endif
