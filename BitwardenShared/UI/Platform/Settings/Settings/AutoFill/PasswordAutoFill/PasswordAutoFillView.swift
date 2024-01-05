import SwiftUI

// MARK: - PasswordAutoFillView

/// A view that shows the instructions for enabling password autofill.
///
struct PasswordAutoFillView: View {
    // MARK: View

    var body: some View {
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
        .navigationBar(title: Localizations.passwordAutofill, titleDisplayMode: .inline)
    }

    // MARK: Private Views

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

#Preview {
    PasswordAutoFillView()
}
