import BitwardenSdk
import SwiftUI

/// A view for editing an item
struct EditAuthenticatorItemView: View {
    // MARK: Properties

    @ObservedObject var store: Store<
        EditAuthenticatorItemState,
        EditAuthenticatorItemAction,
        EditAuthenticatorItemEffect
    >

    // MARK: View

    var body: some View {
        content
            .navigationTitle(Localizations.editItem)
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismissPressed)
                }
            }
            .task { await store.perform(.appeared) }
            .toast(store.binding(
                get: \.toast,
                send: EditAuthenticatorItemAction.toastShown
            ))
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                informationSection
                saveButton
            }
            .padding(16)
        }
        .dismissKeyboardImmediately()
        .background(
            Asset.Colors.backgroundSecondary.swiftUIColor
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var informationSection: some View {
        SectionView(Localizations.itemInformation) {
            BitwardenTextField(
                title: Localizations.name,
                text: store.binding(
                    get: \.name,
                    send: EditAuthenticatorItemAction.nameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.authenticatorKey,
                text: store.binding(
                    get: \.totpState.rawAuthenticatorKeyString!,
                    send: EditAuthenticatorItemAction.keyChanged
                ),
                isPasswordVisible: store.binding(
                    get: \.isKeyVisible,
                    send: EditAuthenticatorItemAction.toggleKeyVisibilityChanged
                )
            )
            .textFieldConfiguration(.password)
        }
    }

    private var saveButton: some View {
        AsyncButton(Localizations.save) {
            await store.perform(.savePressed)
        }
        .accessibilityIdentifier("SaveButton")
        .buttonStyle(.primary())
    }
}

#if DEBUG
#Preview("Edit") {
    EditAuthenticatorItemView(
        store: Store(
            processor: StateProcessor(
                state: AuthenticatorItemState(
                    configuration: .existing(
                        authenticatorItemView: AuthenticatorItemView(
                            id: "Example",
                            name: "Example",
                            totpKey: "example"
                        )
                    ),
                    name: "Example",
                    totpState: LoginTOTPState(
                        authKeyModel: TOTPKeyModel(authenticatorKey: "example")!,
                        codeModel: TOTPCodeModel(
                            code: "123456",
                            codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                            period: 30
                        )
                    )
                )
                .editState
            )
        )
    )
}
#endif
