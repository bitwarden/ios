import BitwardenSdk
import SwiftUI

/// A view for editing a token
struct EditTokenView: View {
    // MARK: Properties

    @ObservedObject var store: Store<EditTokenState, EditTokenAction, EditTokenEffect>

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
                send: EditTokenAction.toastShown
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
                    send: EditTokenAction.nameChanged
                )
            )

            BitwardenTextField(
                title: Localizations.authenticatorKey,
                text: store.binding(
                    get: \.totpState.rawAuthenticatorKeyString!,
                    send: EditTokenAction.keyChanged
                ),
                isPasswordVisible: store.binding(
                    get: \.isKeyVisible,
                    send: EditTokenAction.toggleKeyVisibilityChanged
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
    EditTokenView(
        store: Store(
            processor: StateProcessor(
                state: TokenItemState(
                    configuration: .existing(
                        token: Token(
                            name: "Example",
                            authenticatorKey: "example"
                        )!
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
