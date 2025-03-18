// MARK: - QRCodeParameter

/// An object that encapsulates the parameters necessary for a particular type of QR code.
/// This tracks what the name of the parameter is, along with the available options, and what
/// is currently selected.
struct QRCodeParameter: Equatable, Hashable, Sendable {
    /// The name of the parameter, e.g. "SSID".
    let name: String

    /// A list of available cipher fields that can be used for this parameter.
    let options: [CipherFieldType]

    /// A localized string for how the parameter is asked for in the UI.
    var parameterTitle: String { Localizations.fieldFor(name) }

    /// The currently selected cipher field for this parameter.
    var selected: CipherFieldType

    /// Initializes a `QRCodeParameter` from a name, available options, and priority list
    /// of how the initially selected field should be determined.
    ///
    /// - Parameters:
    ///   - name: The name of the parameter, e.g. "SSID".
    ///   - options: A list of available cipher fields that can be used for this parameter.
    ///   - fieldPriority: The order in which to select the initial value, if it exists.
    ///   - isOptional: Whether the parameter is required; if this is false, `.none` will be added as an option.
    init(
        name: String,
        options: [CipherFieldType],
        fieldPriority: [CipherFieldType] = [],
        isOptional: Bool = false
    ) {
        self.name = name
        let allOptions = isOptional ? [.none] + options : options
        self.options = allOptions
        selected = fieldPriority.first(where: { allOptions.contains($0) })
            ?? allOptions.first // Since if .none is available it will be first
            ?? .none
    }
}
