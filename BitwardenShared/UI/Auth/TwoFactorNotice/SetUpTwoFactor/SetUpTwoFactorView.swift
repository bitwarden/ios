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
            if verticalSizeClass == .regular {
                VStack(spacing: 24) {
                    // Despite the image being 96x96, the actual dimensions of the
                    // illustration within that are 96x72 (4:3).
                    // So to make how it interacts with other elements correct,
                    // we have to apply negative padding equal to 1/8 of the width
                    // to both top and bottom, thus making the image the "correct" size
                    Asset.Images.Illustrations.userLock.swiftUIImage
                        .resizable()
                        .frame(width: 124, height: 124)
                        .padding(.vertical, -15.5)

                    textPortion
                }
                .padding(.top, 16)
            } else {
                HStack(spacing: 32) {
                    Asset.Images.Illustrations.userLock.swiftUIImage
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(.vertical, -12.5)

                    textPortion
                }
                .padding(.horizontal, 80)
                .padding(.top, 16) // Being a scroll view gives us 16 already
            }

            buttons
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

    // MARK: Private

    private var buttons: some View {
        VStack(spacing: 12) {
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
    }

    private var textPortion: some View {
        VStack(spacing: 12) {
            Text(Localizations.setUpTwoStepLogin)
                .styleGuide(.title2, weight: .semibold)

            Text(Localizations.youCanSetUpTwoStepLoginAsAnAlternativeDescriptionLong)
                .styleGuide(.body)
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
