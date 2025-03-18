import BitwardenSdk

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

struct QRCodeParameter2: Equatable, Hashable, Sendable {
    /// A localized string for how the parameter is asked for in the UI.
    var parameterTitle: String { Localizations.fieldFor(name) }

    /// The name of the parameter, e.g. "SSID".
    let name: String

    /// A list of available cipher fields that can be used for this parameter.
    let options: [CipherFieldType]

    /// The currently selected cipher field for this parameter, by index in `options`.
    let selectedIndex: Int
}

protocol QRCodeTypeState: Equatable {
    var parameters: [QRCodeParameter2] { get }

    var qrEncodableString: String { get }

    init(cipher: CipherView)
}

struct TypeState2: Equatable {
    static func == (lhs: TypeState2, rhs: TypeState2) -> Bool {
        return lhs.internalState.parameters == rhs.internalState.parameters
            && lhs.internalState.qrEncodableString == rhs.internalState.qrEncodableString
        }
    let internalState: any QRCodeTypeState
}

struct WifiQRCodeState: QRCodeTypeState {
    let cipher: CipherView

    var qrEncodableString: String {
        "WIFI"
    }

    var parameters: [QRCodeParameter2] = [
        QRCodeParameter2(
            name: Localizations.ssid,
            options: [.username, .password],
            selectedIndex: 0
        ),
        QRCodeParameter2(
            name: Localizations.password,
            options: [.username, .password],
            selectedIndex: 1
        ),
    ]

    init(cipher: CipherView) {
        self.cipher = cipher
    }
}
