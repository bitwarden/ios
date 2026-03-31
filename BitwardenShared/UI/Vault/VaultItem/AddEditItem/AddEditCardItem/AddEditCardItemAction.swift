// MARK: AddEditCardItemAction

/// An enum of actions for adding or editing a card Item in its add/edit state.
///
enum AddEditCardItemAction: Equatable, Sendable {
    /// The brand of the card changed.
    case brandChanged(DefaultableType<CardComponent.Brand>)

    /// The user selected a cardholder name from the disambiguation picker.
    case cardholderNameCandidateSelected(String)

    /// The name of the card holder changed.
    case cardholderNameChanged(String)

    /// The user tapped Cancel in the cardholder name picker, indicating no scanned data should be kept.
    case cardholderNamePickerCancelled

    /// The cardholder name picker was dismissed without selecting a name.
    case cardholderNamePickerDismissed

    /// The number of the card changed.
    case cardNumberChanged(String)

    /// The card scanner sheet was dismissed without completing a scan.
    case cardScannerDismissed

    /// The OCR scanner produced an updated set of recognized text lines.
    case cardScannerLinesUpdated([String])

    /// The security code of the card changed.
    case cardSecurityCodeChanged(String)

    /// The expiration month of the card changed.
    case expirationMonthChanged(DefaultableType<CardComponent.Month>)

    /// The expiration year of the card changed.
    case expirationYearChanged(String)

    /// The user tapped the Scan Card button.
    case scanCardButtonTapped

    /// Toggle for code visibility changed.
    case toggleCodeVisibilityChanged(Bool)

    /// Toggle for number visibility changed.
    case toggleNumberVisibilityChanged(Bool)
}
