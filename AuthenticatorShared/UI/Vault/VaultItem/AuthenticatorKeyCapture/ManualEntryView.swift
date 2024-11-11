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
                title: Localizations.createVerificationCode,
                titleDisplayMode: .inline
            )
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }
            }
            .task {
                await store.perform(.appeared)
            }
    }

    /// A button to trigger an `.addPressed(:)` action.
    ///
    private var addButton: some View {
        let title = store.state.isPasswordManagerSyncActive ?
            Localizations.saveHere :
            Localizations.addCode

        return Button(title) {
            store.send(
                ManualEntryAction.addPressed(
                    code: store.state.authenticatorKey,
                    name: store.state.name,
                    sendToBitwarden: false
                )
            )
        }
        .buttonStyle(.tertiary())
        .accessibilityIdentifier("ManualEntryAddCodeButton")
    }

    /// A button to trigger an `.addPressed(:)` action.
    ///
    ///
    @ViewBuilder private var addToBitwardenButton: some View {
        if store.state.isPasswordManagerSyncActive {
            Button(Localizations.saveToBitwarden) {
                store.send(
                    ManualEntryAction.addPressed(
                        code: store.state.authenticatorKey,
                        name: store.state.name,
                        sendToBitwarden: true
                    )
                )
            }
            .buttonStyle(.primary())
            .accessibilityIdentifier("ManualEntryAddCodeToBitwardenButton")
        }
    }

    /// The main content of the view.
    ///
    private var content: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            Text(Localizations.enterKeyManually)
                .styleGuide(.title2, weight: .bold)
            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.name,
                    send: ManualEntryAction.nameChanged
                )
            )
            .accessibilityIdentifier("ManualEntryNameField")

            BitwardenTextField(
                title: Localizations.key,
                text: store.binding(
                    get: \.authenticatorKey,
                    send: ManualEntryAction.authenticatorKeyChanged
                )
            )
            .accessibilityIdentifier("ManualEntryKeyField")
            addToBitwardenButton
            addButton
            footerButtonContainer
        }
        .background(
            Asset.Colors.backgroundSecondary.swiftUIColor
                .ignoresSafeArea()
        )
        .scrollView()
    }

    /// A view to wrap the button for triggering `.scanCodePressed`.
    ///
    @ViewBuilder private var footerButtonContainer: some View {
        if store.state.deviceSupportsCamera {
            VStack(alignment: .leading, spacing: 0.0, content: {
                Text(Localizations.cannotAddKey)
                    .styleGuide(.callout)
                AsyncButton {
                    await store.perform(.scanCodePressed)
                } label: {
                    Text(Localizations.scanQRCode)
                        .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
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

        var isPasswordManagerSyncActive: Bool = false

        var manualEntryState: ManualEntryState {
            self
        }

        var name: String = ""
    }

    static var previews: some View {
        empty
        textAdded
        syncActive
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
                            authenticatorKey: "manualEntry",
                            name: "Manual Name"
                        ).manualEntryState
                    )
                )
            )
        }
        .previewDisplayName("Text Added")
    }

    @ViewBuilder static var syncActive: some View {
        NavigationView {
            ManualEntryView(
                store: Store(
                    processor: StateProcessor(
                        state: PreviewState(
                            isPasswordManagerSyncActive: true
                        ).manualEntryState
                    )
                )
            )
        }
        .previewDisplayName("Sync Active")
    }
}
#endif
