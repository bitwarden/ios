/// An object that defines the current state of a `ViewAsQRCodeView`.
///
struct ViewAsQRCodeState: Equatable {
    var availableCodeTypes: [QRCodeType] = QRCodeType.allCases

    var string: String

    var qrCodeType: QRCodeType = .wifi

    var ssidFieldOptions = [
        QRCodeFieldReference(qrCodeFieldName: "Username", cipherField: .username),
        QRCodeFieldReference(qrCodeFieldName: "Password", cipherField: .password),
    ]

    var ssidFieldSelection = QRCodeFieldReference(qrCodeFieldName: "Username", cipherField: .username)

    var wifiPasswordFieldOptions = [
        QRCodeFieldReference(qrCodeFieldName: "Password", cipherField: .password),
        QRCodeFieldReference(qrCodeFieldName: "Username", cipherField: .username),
    ]

    var wifiPasswordFieldSelection = QRCodeFieldReference(qrCodeFieldName: "Password", cipherField: .password)

    var additionalProperties = [
        QRCodeAdditionalProperty(
            name: "SSID",
            options: [
                QRCodeFieldReference(qrCodeFieldName: "Username", cipherField: .username),
                QRCodeFieldReference(qrCodeFieldName: "Password", cipherField: .password),
            ],
            selected: QRCodeFieldReference(qrCodeFieldName: "Username", cipherField: .username)
        ),
        QRCodeAdditionalProperty(
            name: "Password",
            options: [
                QRCodeFieldReference(qrCodeFieldName: "Password", cipherField: .password),
                QRCodeFieldReference(qrCodeFieldName: "Username", cipherField: .username),
            ],
            selected: QRCodeFieldReference(qrCodeFieldName: "Password", cipherField: .password)
        ),
    ]
}

enum QRCodeType: CaseIterable, Equatable, Menuable, Sendable {
    case contact
    case url
    case wifi

    static var allCases: [QRCodeType] = [
        .wifi,
        .contact,
        .url,
    ]

    var localizedName: String {
        switch self {
        case .wifi: Localizations.wifi
        case .contact: Localizations.contact
        case .url: Localizations.url
        }
    }
}

enum CipherFieldType: Equatable, Hashable, Sendable {
    case none
    case username
    case password
    case notes
    case uri(index: Int)
    case custom(name: String)
}

struct QRCodeFieldReference: Equatable, Menuable, Sendable {
    let qrCodeFieldName: String
    let cipherField: CipherFieldType

    var localizedName: String { qrCodeFieldName }
}

struct QRCodeAdditionalProperty: Equatable, Hashable, Sendable {
    let name: String
    var fieldTitle: String { "Field for \(name)" }

    let options: [QRCodeFieldReference]
    var selected: QRCodeFieldReference
}
