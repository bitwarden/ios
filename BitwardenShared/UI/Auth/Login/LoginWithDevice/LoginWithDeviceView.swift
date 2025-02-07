import SwiftUI

// MARK: - LoginWithDeviceView

/// A view that allows the user to initiate a login from their device.
///
struct LoginWithDeviceView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<LoginWithDeviceState, LoginWithDeviceAction, LoginWithDeviceEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .center, spacing: 12) {
                titleText

                explanationText
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)

            fingerprintView

            resendNotificationButton

            allLoginOptionsView
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 12)
        .scrollView(padding: 12)
        .navigationBar(title: store.state.navBarText, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private Views

    /// The text and button for viewing all login options.
    private var allLoginOptionsView: some View {
        HStack(spacing: 8) {
            Text(Localizations.needAnotherOption)
                .styleGuide(.subheadline)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)

            Button(Localizations.viewAllLoginOptions) {
                store.send(.dismiss)
            }
            .styleGuide(.subheadlineSemibold)
            .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
            .accessibilityIdentifier("ViewAllLoginOptionsButton")
        }
    }

    /// The explanation text.
    private var explanationText: some View {
        Text(store.state.explanationText)
            .styleGuide(.body)
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
    }

    /// The fingerprint phrase title and display.
    private var fingerprintView: some View {
        ContentBlock {
            VStack(alignment: .leading, spacing: 2) {
                Text(Localizations.fingerprintPhrase)
                    .styleGuide(.body, weight: .semibold)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("FingerprintValueLabel")

                Text(store.state.fingerprintPhrase ?? "")
                    .styleGuide(.bodyMonospaced)
                    .foregroundStyle(Asset.Colors.textCodePink.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .accessibilityIdentifier("FingerprintPhraseValue")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    /// The button to resend the login notification.
    @ViewBuilder private var resendNotificationButton: some View {
        if store.state.isResendNotificationVisible {
            AsyncButton(Localizations.resendNotification) {
                await store.perform(.resendNotification)
            }
            .buttonStyle(.secondary())
            .accessibilityIdentifier("ResendNotificationButton")
        }
    }

    /// The title text.
    private var titleText: some View {
        Text(store.state.titleText)
            .styleGuide(.title2, weight: .semibold)
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
    }
}

// MARK: - Previews

#Preview {
    LoginWithDeviceView(store: Store(processor: StateProcessor(state: LoginWithDeviceState())))
}
