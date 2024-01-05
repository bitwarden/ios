import SwiftUI

// MARK: - AppExtensionView

/// A view that has instructions and a button for activating the app extension.
///
struct AppExtensionView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AppExtensionState, AppExtensionAction, Void>

    // MARK: View

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                instructionsContent

                Spacer()

                image

                Spacer()

                activateButton
            }
            .padding(.vertical, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false)
        }
        .navigationBar(title: Localizations.appExtension, titleDisplayMode: .inline)
    }

    // MARK: Private Views

    /// The activate button.
    private var activateButton: some View {
        Button(
            store.state.extensionActivated ?
                Localizations.exntesionReenable :
                Localizations.extensionEnable
        ) {
            store.send(.activateButtonTapped)
        }
        .buttonStyle(.tertiary())
    }

    /// The instruction image.
    private var image: some View {
        Image(asset: Asset.Images.appExtensionPreview)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 281)
            .accessibilityHidden(true)
    }

    /// The instructions text.
    private var instructionsContent: some View {
        VStack(spacing: 20) {
            instructionsTitle

            instructionsBody
        }
    }

    /// The instructions body.
    private var instructionsBody: some View {
        Text(
            store.state.extensionActivated ?
                Localizations.extensionInSafari :
                Localizations.extensionTurnOn
        )
        .styleGuide(.body)
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The instructions title.
    private var instructionsTitle: some View {
        Text(
            store.state.extensionActivated ?
                Localizations.extensionReady :
                Localizations.extensionInstantAccess
        )
        .styleGuide(.title)
        .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Previews

#Preview("Not Activated") {
    AppExtensionView(store: Store(processor: StateProcessor(state: AppExtensionState(extensionActivated: false))))
}

#Preview("Activated") {
    AppExtensionView(store: Store(processor: StateProcessor(state: AppExtensionState(extensionActivated: true))))
}
