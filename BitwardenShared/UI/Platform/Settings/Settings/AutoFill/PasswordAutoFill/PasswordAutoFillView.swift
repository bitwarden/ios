import AuthenticationServices
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

    // MARK: View

    var body: some View {
        Group {
            if store.state.nativeCreateAccountFeatureFlag {
                contentView
            } else {
                legacyContentView
            }
        }
        .navigationBar(
            title: store.state.navigationBarTitle,
            titleDisplayMode: .inline
        )
        .task {
            await store.perform(.appeared)
        }
    }

    // MARK: Private Views

    /// The content view.
    private var contentView: some View {
        VStack(spacing: 0) {
            ZStack {
                gifViewPlaceholder

                gifView
            }
            .frame(width: 230, height: 278)
            .padding(.top, 32)

            Text(Localizations.turnOnAutoFill)
                .styleGuide(.title2, weight: .bold)
                .padding(.top, 32)

            Text(Localizations.useAutoFillToLogIntoYourAccountsWithASingleTap)
                .styleGuide(.body)
                .multilineTextAlignment(.center)
                .padding([.top, .horizontal], 16)

            autofillInstructions
                .padding(.top, 32)

            Text(
                LocalizedStringKey(
                    Localizations.needHelpCheckOutAutofillHelp(
                        ExternalLinksConstants.autofillHelp)
                )
            )
            .styleGuide(.subheadline)
            .tint(Asset.Colors.textInteraction.swiftUIColor)
            .padding(.top, 32)

            Button(Localizations.continue) {
                if #available(iOS 17, *) {
                    ASSettingsHelper.openVerificationCodeAppSettings()
                } else {
                    openURL(ExternalLinksConstants.passwordOptions)
                }
            }
            .buttonStyle(.primary())
            .padding(.top, 32)
            .padding(.bottom, 12)

            if store.state.mode == .onboarding {
                AsyncButton(Localizations.turnOnLater) {
                    await store.perform(.turnAutoFillOnLaterButtonTapped)
                }
                .buttonStyle(.transparent)
            }
        }
        .scrollView(addVerticalPadding: false)
    }

    /// The legacy content view.
    private var legacyContentView: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                instructionsContent

                Spacer()

                imageView

                Spacer()
            }
            .padding(.vertical, 16)
            .frame(minHeight: geometry.size.height)
            .scrollView(addVerticalPadding: false)
        }
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
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// The current auto fill instructions to present in the list.
    private var autofillInstructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEachIndexed(store.state.autofillInstructions, id: \.self) { index, instruction in
                Group {
                    HStack(spacing: 0) {
                        Text("\(index + 1)")
                            .styleGuide(.title)
                            .foregroundColor(Asset.Colors.textCodeBlue.swiftUIColor)
                            .frame(width: 34, height: 60, alignment: .leading)

                        Text(LocalizedStringKey(instruction))
                            .styleGuide(.body)
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)

                    if index < store.state.autofillInstructions.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
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
            .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Settings") {
    PasswordAutoFillView(
        store: Store(
            processor: StateProcessor(
                state: .init(
                    mode: .settings,
                    nativeCreateAccountFeatureFlag: true
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
                    mode: .onboarding,
                    nativeCreateAccountFeatureFlag: true
                )
            )
        )
    )
}

#Preview("Settings w/ FF off") {
    PasswordAutoFillView(
        store: Store(
            processor: StateProcessor(
                state: .init(mode: .settings)
            )
        )
    )
}
#endif
