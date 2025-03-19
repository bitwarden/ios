import BitwardenSdk

// MARK: - QRCodeType

/// An enum encapsulating the different kinds of data we can encode in a QR code.
enum QRCodeType: CaseIterable, Equatable, Menuable, Sendable {
    case plaintext
    case url
    case wifi

    static var allCases: [QRCodeType] = [
        .plaintext,
        .wifi,
        .url,
    ]

    var localizedName: String {
        switch self {
        case .plaintext: Localizations.plaintext
        case .wifi: Localizations.wifi
        case .url: Localizations.url
        }
    }

    func newState(cipher: CipherView) -> any QRCodeTypeState {
        switch self {
        case .plaintext:
            PlaintextQRCodeState(cipher: cipher) as any QRCodeTypeState
        case .url:
            URLQRCodeState(cipher: cipher) as any QRCodeTypeState
        case .wifi:
            WifiQRCodeState(cipher: cipher) as any QRCodeTypeState
        }
    }
}

/// A protocol that encapsulates the logic for generating a QR code.
protocol QRCodeTypeState: Equatable {
    var parameters: [QRCodeParameter] { get set }

    var qrEncodableString: String { get }

    var type: QRCodeType { get }

    init(cipher: CipherView)
}

// MARK: - PlaintextQRCodeState

struct PlaintextQRCodeState: QRCodeTypeState {
    let cipher: CipherView

    var qrEncodableString: String {
        cipher.value(of: parameters[0].selected) ?? ""
    }

    var parameters: [QRCodeParameter]

    let type = QRCodeType.plaintext

    init(cipher: CipherView) {
        self.cipher = cipher

        parameters = [
            QRCodeParameter(
                name: Localizations.url,
                options: cipher.availableFields,
                fieldPriority: [.notes]
            ),
        ]
    }
}

// MARK: - URLQRCodeState

struct URLQRCodeState: QRCodeTypeState {
    let cipher: CipherView

    var qrEncodableString: String {
        cipher.value(of: parameters[0].selected) ?? "Error"
    }

    var parameters: [QRCodeParameter]

    let type = QRCodeType.url

    init(cipher: CipherView) {
        self.cipher = cipher

        let priorities: [CipherFieldType]
        switch cipher.type {
        case .login:
            priorities = [.uri(index: 0)]
        case .secureNote:
            priorities = [.notes]
        default:
            priorities = []
        }

        parameters = [
            QRCodeParameter(
                name: Localizations.url,
                options: cipher.availableFields,
                fieldPriority: priorities
            ),
        ]
    }
}

// MARK: - WifiQRCodeState

struct WifiQRCodeState: QRCodeTypeState {
    let cipher: CipherView

    var qrEncodableString: String {
        let ssid = cipher.value(of: parameters[0].selected) ?? "Error"
        let password = cipher.value(of: parameters[1].selected)
        var passwordPart: String?
        if let password {
            passwordPart = "P:\(password);"
        }
        return "WIFI:T:WPA;S:\(ssid);\(passwordPart ?? "");"
    }

    var parameters: [QRCodeParameter]

    let type = QRCodeType.wifi

    init(cipher: CipherView) {
        self.cipher = cipher

        parameters = [
            QRCodeParameter(
                name: Localizations.ssid,
                options: cipher.availableFields,
                fieldPriority: [
                    .username,
                    .custom(name: "SSID"),
                ]
            ),
            QRCodeParameter(
                name: Localizations.password,
                options: cipher.availableFields,
                fieldPriority: [.password],
                isOptional: true
            ),
        ]
    }
}
