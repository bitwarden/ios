import BitwardenSdk
import SwiftUI

// MARK: - ViewTokenItemView

/// A view for displaying the contents of a token item.
struct ViewTokenItemView: View {
    // MARK: Private Properties

    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<TokenItemState, ViewTokenAction, ViewTokenEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        if let totpModel = store.state.totpCode {
            BitwardenField(
                title: Localizations.verificationCodeTotp,
                content: {
                    Text(totpModel.displayCode)
                        .styleGuide(.bodyMonospaced)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                },
                accessoryContent: {
                    TOTPCountdownTimerView(
                        timeProvider: timeProvider,
                        totpCode: totpModel,
                        onExpiration: {
                            Task {
                                await store.perform(.totpCodeExpired)
                            }
                        }
                    )
                    Button {
                        store.send(.copyPressed(value: totpModel.code))
                    } label: {
                        Asset.Images.copy.swiftUIImage
                            .imageStyle(.accessoryIcon)
                    }
                    .accessibilityLabel(Localizations.copy)
                }
            )
        } else {
            Text("Something went wrong.")
        }
    }
}

// MARK: Previews

#Preview("Code") {
    ViewTokenItemView(
        store: Store(
            processor: StateProcessor(
                state:
                TokenItemState(
                    configuration: .add,
                    name: "Example",
                    totpState: LoginTOTPState(
                        authKeyModel: TOTPKeyModel(authenticatorKey: "ASDF")!,
                        codeModel: TOTPCodeModel(
                            code: "123123",
                            codeGenerationDate: Date(timeIntervalSinceReferenceDate: 0),
                            period: 30
                        )
                    )
                )
            )
        ),
        timeProvider: PreviewTimeProvider(
            fixedDate: Date(
                timeIntervalSinceReferenceDate: 0
            )
        )
    )
}
