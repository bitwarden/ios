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
            passwordText

            generateButton

            instructionsPreventAccountLockView
        }
        .scrollView()
        .navigationBar(
            title: Localizations.generateMasterPassword,
            titleDisplayMode: .inline
        )
        .toolbar {
            saveToolbarItem {
                await store.perform(.save)
            }
        }
        .task {
            await store.perform(.loadData)
        }
    }

    // MARK: Private views

    /// The generated password view.
    private var passwordText: some View {
        PasswordText(
            password: store.state.generatedPassword,
            isPasswordVisible: true
        )
        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        VStack(alignment: .leading, spacing: 0) {
            Text(Localizations.writeThisPasswordDownAndKeepItSomewhereSafe)
                .styleGuide(.footnote)
                .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.send(.preventAccountLock)
            } label: {
                Text(Localizations.learnAboutOtherWaysToPreventAccountLockout)
                    .styleGuide(.footnote, weight: .semibold)
                    .foregroundStyle(Asset.Colors.textInteraction.swiftUIColor)
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
