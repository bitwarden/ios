import SwiftUI

// MARK: - ManualEntryView

/// A view for the user to manually enter an authenticator key.
///
struct ManualEntryView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ManualEntryState, ManualEntryAction, ManualEntryEffect>

    var body: some View {
        content
            .navigationBar(
                title: Localizations.authenticatorKey,
                titleDisplayMode: .inline
            )
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }

                saveToolbarItem {
                    store.send(
                        ManualEntryAction.addPressed(code: store.state.authenticatorKey)
                    )
                }
            }
    }

    /// The main content of the view.
    ///
    private var content: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(alignment: .center, spacing: 12) {
                Text(Localizations.enterKeyManually)
                    .styleGuide(.title2, weight: .semibold)

                Text(Localizations.onceTheKeyIsSuccessfullyEntered)
                    .styleGuide(.body)
            }
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)

            BitwardenTextField(
                title: Localizations.authenticatorKey,
                text: store.binding(
                    get: \.authenticatorKey,
                    send: ManualEntryAction.authenticatorKeyChanged
                ),
                accessibilityIdentifier: "AddTOTPManuallyField"
            )

            footerButtonContainer
        }
        .background(
            Asset.Colors.backgroundPrimary.swiftUIColor
                .ignoresSafeArea()
        )
        .padding(.top, 12)
        .scrollView(padding: 12)
    }

    /// A view to wrap the button for triggering `.scanCodePressed`.
    ///
    @ViewBuilder private var footerButtonContainer: some View {
        if store.state.deviceSupportsCamera {
            VStack(alignment: .center, spacing: 0.0, content: {
                Text(Localizations.cannotAddAuthenticatorKey)
                    .styleGuide(.subheadline)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)

                AsyncButton {
                    await store.perform(.scanCodePressed)
                } label: {
                    Text(Localizations.scanQRCode)
                        .foregroundColor(Asset.Colors.textInteraction.swiftUIColor)
                        .styleGuide(.callout)
                }
                .buttonStyle(InlineButtonStyle())
            })
        }
    }
}

#if DEBUG
struct ManualEntryView_Previews: PreviewProvider {
    struct PreviewState: ManualEntryState {
        var authenticatorKey: String = ""

        var deviceSupportsCamera: Bool = true

        var manualEntryState: ManualEntryState {
            self
        }
    }

    static var previews: some View {
        empty
        textAdded
    }

    @ViewBuilder static var empty: some View {
        NavigationView {
            ManualEntryView(
                store: Store(
                    processor: StateProcessor(
                        state: PreviewState().manualEntryState
                    )
                )
            )
        }
        .previewDisplayName("Empty")
    }

    @ViewBuilder static var textAdded: some View {
        NavigationView {
            ManualEntryView(
                store: Store(
                    processor: StateProcessor(
                        state: PreviewState(
                            authenticatorKey: "manualEntry"
                        ).manualEntryState
                    )
                )
            )
        }
        .previewDisplayName("Text Added")
    }
}
#endif
