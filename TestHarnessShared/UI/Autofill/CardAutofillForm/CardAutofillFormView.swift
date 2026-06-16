import BitwardenKit
import SwiftUI

/// A view that displays a card form for testing card autofill functionality.
///
@available(iOS 17, *)
struct CardAutofillFormView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<CardAutofillFormState, CardAutofillFormAction, CardAutofillFormEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private Views

    /// The main content view.
    private var content: some View {
        Form {
            Section {
                TextField(
                    Localizations.cardholderName,
                    text: store.binding(
                        get: \.cardholderName,
                        send: CardAutofillFormAction.cardholderNameChanged,
                    ),
                )
                .textContentType(.creditCardName)
                .autocorrectionDisabled()

                TextField(
                    Localizations.cardNumber,
                    text: store.binding(
                        get: \.cardNumber,
                        send: CardAutofillFormAction.cardNumberChanged,
                    ),
                )
                .textContentType(.creditCardNumber)
                .keyboardType(.numberPad)

                TextField(
                    Localizations.expirationMonth,
                    text: store.binding(
                        get: \.expirationMonth,
                        send: CardAutofillFormAction.expirationMonthChanged,
                    ),
                )
                .textContentType(.creditCardExpirationMonth)
                .keyboardType(.numberPad)

                TextField(
                    Localizations.expirationYear,
                    text: store.binding(
                        get: \.expirationYear,
                        send: CardAutofillFormAction.expirationYearChanged,
                    ),
                )
                .textContentType(.creditCardExpirationYear)
                .keyboardType(.numberPad)

                TextField(
                    Localizations.securityCode,
                    text: store.binding(
                        get: \.securityCode,
                        send: CardAutofillFormAction.securityCodeChanged,
                    ),
                )
                .textContentType(.creditCardSecurityCode)
                .keyboardType(.numberPad)
            } header: {
                Text(Localizations.cardDetails)
            } footer: {
                Text(Localizations.cardAutofillFormDescriptionLong)
            }

            Section {
                if store.state.hasAnyValue {
                    VStack(alignment: .leading, spacing: 8) {
                        if !store.state.cardholderName.isEmpty {
                            Text(Localizations.xColonY(Localizations.cardholderName, store.state.cardholderName))
                                .styleGuide(.body)
                        }
                        if !store.state.cardNumber.isEmpty {
                            Text(Localizations.xColonY(Localizations.cardNumber, store.state.cardNumber))
                                .styleGuide(.body)
                        }
                        if !store.state.expirationMonth.isEmpty {
                            Text(Localizations.xColonY(Localizations.expirationMonth, store.state.expirationMonth))
                                .styleGuide(.body)
                        }
                        if !store.state.expirationYear.isEmpty {
                            Text(Localizations.xColonY(Localizations.expirationYear, store.state.expirationYear))
                                .styleGuide(.body)
                        }
                        if !store.state.securityCode.isEmpty {
                            Text(Localizations.xColonY(Localizations.securityCode, store.state.securityCode))
                                .styleGuide(.body)
                        }
                    }
                } else {
                    Text(Localizations.enterCardDetailsAbove)
                        .foregroundColor(.secondary)
                        .styleGuide(.body)
                }
            } header: {
                Text(Localizations.formValues)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17, *)
#Preview {
    NavigationView {
        CardAutofillFormView(store: Store(processor: StateProcessor(state: CardAutofillFormState())))
    }
}
#endif
