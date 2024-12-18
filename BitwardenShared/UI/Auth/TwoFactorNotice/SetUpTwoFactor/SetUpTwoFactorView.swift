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
        VStack(spacing: 12) {
            dynamicStackView(minHeight: 0) {
                Asset.Images.Illustrations.userLock.swiftUIImage
                    .resizable()
                    .frame(
                        width: verticalSizeClass == .regular ? 152 : 124,
                        height: verticalSizeClass == .regular ? 152 : 124
                    )
                    .accessibilityHidden(true)
            } textContent: {
                VStack(spacing: 16) {
                    Text(Localizations.setUpTwoStepLogin)
                        .styleGuide(.title, weight: .bold)

                    Text(Localizations.youCanSetUpTwoStepLoginAsAnAlternative)
                        .styleGuide(.title3)
                }
                .padding(.horizontal, 12)
            }

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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Asset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .scrollView()
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
    }

    /// A dynamic stack view that lays out content vertically when in a regular vertical size class
    /// and horizontally for the compact vertical size class.
    @ViewBuilder
    private func dynamicStackView(
        minHeight: CGFloat,
        @ViewBuilder imageContent: () -> some View,
        @ViewBuilder textContent: () -> some View
    ) -> some View {
        Group {
            if verticalSizeClass == .regular {
                VStack(spacing: 24) {
                    imageContent()
                    textContent()
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, minHeight: minHeight)
            } else {
                HStack(alignment: .top, spacing: 40) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        imageContent()
                            .padding(.leading, 36)
                            .padding(.vertical, 16)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: minHeight)

                    textContent()
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, minHeight: minHeight)
                }
            }
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
                        allowDelay: true
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
                        allowDelay: false
                    )
                )
            )
        )
    }
}
#endif
