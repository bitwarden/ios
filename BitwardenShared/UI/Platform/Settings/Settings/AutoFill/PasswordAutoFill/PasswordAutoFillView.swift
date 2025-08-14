import AuthenticationServices
import BitwardenResources
import SwiftUI

// MARK: - PasswordAutoFillView

/// A view that shows the instructions for enabling password autofill.
///
struct PasswordAutoFillView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<
        PasswordAutoFillState,
        Void,
        PasswordAutoFillEffect
    >

    /// An object used to determine the current color scheme.
    @Environment(\.colorScheme) var colorScheme

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// An environment variable for getting the vertical size class of the view.
    @Environment(\.verticalSizeClass) var verticalSizeClass

    // MARK: View

    var body: some View {
        Group {
            contentView
        }
        .navigationBar(
            title: store.state.navigationBarTitle,
            titleDisplayMode: .inline
        )
        .task {
            await store.perform(.checkAutofillOnForeground)
        }
    }

    // MARK: Private Views

    /// The content view.
    private var contentView: some View {
        VStack(spacing: 24) {
            dynamicStackView {
                ZStack {
                    gifViewPlaceholder

                    gifView
                }
                .frame(width: 230, height: 278)

                VStack(spacing: 12) {
                    Text(Localizations.turnOnAutoFill)
                        .styleGuide(.title2, weight: .bold)

                    Text(Localizations.useAutoFillToLogIntoYourAccountsWithASingleTap)
                        .styleGuide(.body)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)

            autofillInstructions

            Text(
                LocalizedStringKey(
                    Localizations.needHelpCheckOutAutofillHelp(
                        ExternalLinksConstants.autofillHelp)
                )
            )
            .styleGuide(.subheadline)
            .tint(SharedAsset.Colors.textInteraction.swiftUIColor)

            VStack(spacing: 12) {
                Button(Localizations.continue) {
                    if #available(iOS 17, *) {
                        ASSettingsHelper.openVerificationCodeAppSettings()
                    } else {
                        openURL(ExternalLinksConstants.passwordOptions)
                    }
                }
                .buttonStyle(.primary())

                if store.state.mode == .onboarding {
                    AsyncButton(Localizations.turnOnLater) {
                        await store.perform(.turnAutoFillOnLaterButtonTapped)
                    }
                    .buttonStyle(.secondary())
                }
            }
        }
        .scrollView(addVerticalPadding: false)
    }

    /// The view used for displaying the gif content.
    @ViewBuilder private var gifView: some View {
        switch colorScheme {
        case .light:
            GifView(gif: Asset.Images.autofillIosLight)
        case .dark:
            GifView(gif: Asset.Images.autofillIosDark)
        @unknown default:
            GifView(gif: Asset.Images.autofillIosLight)
        }
    }

    /// The placeholder image to present while the gif loads.
    @ViewBuilder private var gifViewPlaceholder: some View {
        switch colorScheme {
        case .light:
            Image(decorative: Asset.Images.autofillIosLightPlaceholder)
                .resizable()
                .scaledToFit()
        case .dark:
            Image(decorative: Asset.Images.autofillIosDarkPlaceholder)
                .resizable()
                .scaledToFit()
        @unknown default:
            Image(decorative: Asset.Images.autofillIosLightPlaceholder)
                .resizable()
                .scaledToFit()
        }
    }

    /// The preview image of what the extension will look like.
    private var imageView: some View {
        Image(asset: Asset.Images.passwordAutofillPreview)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 276)
            .accessibilityHidden(true)
    }

    /// The detailed instructions.
    private var instructions: some View {
        Text(Localizations.autofillTurnOn)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// The current auto fill instructions to present in the list.
    private var autofillInstructions: some View {
        NumberedList {
            ForEach(store.state.autofillInstructions, id: \.self) { instruction in
                NumberedListRow(title: instruction)
            }
        }
    }

    /// The list of step by step instructions.
    private var instructionsList: some View {
        let instructionsList = [
            Localizations.autofillTurnOn1,
            Localizations.autofillTurnOn2,
            Localizations.autofillTurnOn3,
            Localizations.autofillTurnOn4,
            Localizations.autofillTurnOn5,
        ].joined(separator: "\n")

        return Text(instructionsList)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The instructions text content.
    private var instructionsContent: some View {
        VStack(spacing: 20) {
            title

            instructions

            instructionsList
        }
    }

    /// The title of the instructions.
    private var title: some View {
        Text(Localizations.extensionInstantAccess)
            .styleGuide(.title)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// A dynamic stack view that lays out content vertically when in a regular vertical size class
    /// and horizontally for the compact vertical size class.
    @ViewBuilder
    private func dynamicStackView(@ViewBuilder content: () -> some View) -> some View {
        if verticalSizeClass == .regular {
            VStack(spacing: 24, content: content)
        } else {
            HStack(spacing: 24, content: content)
                .padding(.horizontal, 80)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Settings") {
    PasswordAutoFillView(
        store: Store(
            processor: StateProcessor(
                state: .init(
                    mode: .settings
                )
            )
        )
    )
}

#Preview("Onboarding") {
    PasswordAutoFillView(
        store: Store(
            processor: StateProcessor(
                state: .init(
                    mode: .onboarding
                )
            )
        )
    )
}
#endif
