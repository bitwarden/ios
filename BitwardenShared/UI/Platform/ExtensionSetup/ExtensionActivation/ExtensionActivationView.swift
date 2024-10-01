import SwiftUI

// MARK: - ExtensionActivationView

/// A view that confirms the user enabled and set up an app extension.
///
struct ExtensionActivationView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ExtensionActivationState, ExtensionActivationAction, Void>

    /// The title text in the view.
    var title: String {
        switch store.state.extensionType {
        case .appExtension:
            Localizations.extensionActivated
        case .autofillExtension:
            Localizations.autofillActivated
        }
    }

    /// The message text in the view.
    var message: String {
        switch store.state.extensionType {
        case .appExtension:
            Localizations.extensionSetup +
                .newLine +
                Localizations.extensionSetup2
        case .autofillExtension:
            Localizations.autofillSetup +
                .newLine +
                Localizations.autofillSetup2
        }
    }

    /// The image to display in the view.
    @ViewBuilder var image: some View {
        switch store.state.extensionType {
        case .appExtension:
            Image(decorative: Asset.Images.bwLogo)
                .resizable()
                .frame(width: 70, height: 70)
                .padding(16)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Asset.Colors.strokeDivider.swiftUIColor, lineWidth: 1.5)
                }
        case .autofillExtension:
            Image(decorative: Asset.Images.check)
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(.green)
        }
    }

    // MARK: View

    var body: some View {
        VStack(spacing: 64) {
            VStack(spacing: 20) {
                Text(title)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.title3)

                Text(message)
                    .foregroundStyle(Asset.Colors.textSecondary.swiftUIColor)
                    .styleGuide(.body)
            }
            .multilineTextAlignment(.center)

            image
        }
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.cancelTapped)
            }
        }
    }
}

// MARK: - Previews

#Preview("Autofill Extension") {
    NavigationView {
        ExtensionActivationView(
            store: Store(
                processor: StateProcessor(
                    state: ExtensionActivationState(
                        extensionType: .autofillExtension
                    )
                )
            )
        )
    }
}

#Preview("App Extension") {
    NavigationView {
        ExtensionActivationView(
            store: Store(
                processor: StateProcessor(
                    state: ExtensionActivationState(
                        extensionType: .appExtension
                    )
                )
            )
        )
    }
}
