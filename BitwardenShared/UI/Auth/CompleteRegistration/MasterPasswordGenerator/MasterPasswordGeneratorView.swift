import SwiftUI

// MARK: - MasterPasswordGeneratorView

/// A view that allows the user to generate a master password.
///
struct MasterPasswordGeneratorView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        MasterPasswordGeneratorState,
        MasterPasswordGeneratorAction,
        MasterPasswordGeneratorEffect
    >

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            passwordTextField

            generateButton

            instructionsPreventAccountLockView
        }
        .scrollView()
        .navigationBar(title: Localizations.generateMasterPassword, titleDisplayMode: .inline)
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
            saveToolbarItem {
                store.send(.save)
            }
        }
        .task {
            await store.perform(.loadData)
        }
    }

    // MARK: Private views

    /// The generated password text field.
    private var passwordTextField: some View {
        BitwardenTextField(text: store.binding(
            get: \.generatedPassword,
            send: MasterPasswordGeneratorAction.masterPasswordChanged
        ))
        .submitLabel(.done)
        .onSubmit {
            store.send(.save)
        }
    }

    /// The generate button.
    private var generateButton: some View {
        AsyncButton {
            await store.perform(.generate)
        } label: {
            HStack(spacing: 8) {
                Image(decorative: Asset.Images.restart2)

                Text(Localizations.generate)
            }
        }
        .buttonStyle(.primary(shouldFillWidth: true))
    }

    /// The password instructions and prevent account lockout button.
    private var instructionsPreventAccountLockView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localizations.writeThisPasswordDownAndKeepItSomewhereSafe)
                .styleGuide(.footnote)
                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.send(.preventAccountLock)
            } label: {
                Text(Localizations.learnAboutOtherWaysToPreventAccountLockout)
                    .styleGuide(.footnote, weight: .semibold)
                    .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    MasterPasswordGeneratorView(
        store: Store(
            processor: StateProcessor(
                state: MasterPasswordGeneratorState(generatedPassword: "Imma-Little-Teapot2")
            )
        )
    )
}
#endif
