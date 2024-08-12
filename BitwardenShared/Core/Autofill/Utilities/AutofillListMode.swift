/// The mode in which the autofil list presents its items.
public enum AutofillListMode {
    /// The autofill list only shows ciphers for password autofill.
    case passwords
    /// The autofill list shows both passwords and Fido2 items in the same section.
    case combinedSingleSection
    /// The autofill list shows both passwords and Fido2 items grouped per section.
    case combinedMultipleSections
}
