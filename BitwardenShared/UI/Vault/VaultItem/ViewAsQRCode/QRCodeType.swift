// MARK: - QRCodeParameter

/// An object that encapsulates the parameters necessary for a particular type of QR code.
struct QRCodeParameter: Equatable, Hashable, Sendable {
    /// The name of the parameter, e.g. "SSID".
    let name: String

    /// Whether or not the parameter is optional.
    let isOptional: Bool

    /// The prioritized order of fields in a cipher to pull the value of the parameter from
    /// when constructing the string encoded in the QR code.
    let fieldPriority: [CipherFieldType]

    var fieldTitle: String { Localizations.fieldFor(name) }
}

// MARK: - QRCodeType

/// An enum encapsulating the different kinds of data we can encode in a QR code.
enum QRCodeType: CaseIterable, Equatable, Menuable, Sendable {
    case url
    case wifi

    static var allCases: [QRCodeType] = [
        .wifi,
        .url,
    ]

    var localizedName: String {
        switch self {
        case .wifi: Localizations.wifi
        case .url: Localizations.url
        }
    }

    var expectedFields: [QRCodeParameter] {
        switch self {
        case .wifi:
            [
                QRCodeParameter(
                    name: Localizations.ssid,
                    isOptional: false,
                    fieldPriority: [
                        .username,
                        .custom(name: "SSID"),
                    ]
                ),
                QRCodeParameter(
                    name: Localizations.password,
                    isOptional: true,
                    fieldPriority: [.password]
                ),
            ]
        case .url:
            [
                QRCodeParameter(
                    name: Localizations.url,
                    isOptional: false,
                    fieldPriority: [.uri(index: 0)]
                ),
            ]
        }
    }
}
