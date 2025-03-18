import BitwardenSdk

// MARK: - QRCodeParameter

/// An object that encapsulates the parameters necessary for a particular type of QR code.
struct QRCodeParameterOld: Equatable, Hashable, Sendable {
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

    var expectedFields: [QRCodeParameterOld] {
        switch self {
        case .wifi:
            [
                QRCodeParameterOld(
                    name: Localizations.ssid,
                    isOptional: false,
                    fieldPriority: [
                        .username,
                        .custom(name: "SSID"),
                    ]
                ),
                QRCodeParameterOld(
                    name: Localizations.password,
                    isOptional: true,
                    fieldPriority: [.password]
                ),
            ]
        case .url:
            [
                QRCodeParameterOld(
                    name: Localizations.url,
                    isOptional: false,
                    fieldPriority: [.uri(index: 0)]
                ),
            ]
        }
    }
}

struct QRCodeParameter: Equatable, Hashable, Sendable {
    /// A localized string for how the parameter is asked for in the UI.
    var parameterTitle: String { Localizations.fieldFor(name) }

    /// The name of the parameter, e.g. "SSID".
    let name: String

    /// A list of available cipher fields that can be used for this parameter.
    let options: [CipherFieldType]

    /// The currently selected cipher field for this parameter.
    var selected: CipherFieldType

    init(
        name: String,
        options: [CipherFieldType],
        fieldPriority: [CipherFieldType],
        isOptional: Bool = false
    ) {
        self.name = name
//        self.options = options
        self.options = isOptional ? [.none] + options : options
        self.selected = QRCodeParameter.initialSelectedField(
            available: options,
            priority: fieldPriority
        )
    }

    static func initialSelectedField(available: [CipherFieldType], priority: [CipherFieldType]) -> CipherFieldType {
        for potentialField in priority {
            if available.contains(potentialField) {
                return potentialField
            }
        }
        if available.contains(.none) { return .none }
        return available.first ?? .username
    }
}

protocol QRCodeTypeState: Equatable {
    var parameters: [QRCodeParameter] { get set }

    var qrEncodableString: String { get }

    init(cipher: CipherView)
}

extension QRCodeTypeState {
    func initialSelectedFieldForParameter(available: [CipherFieldType], priority: [CipherFieldType]) -> CipherFieldType {
        for potentialField in priority {
            if available.contains(potentialField) {
                return potentialField
            }
        }
        if available.contains(.none) { return .none }
        return available.first ?? .username
    }
}

struct TypeState2: Equatable {
    static func == (lhs: TypeState2, rhs: TypeState2) -> Bool {
        return lhs.internalState.parameters == rhs.internalState.parameters
        && lhs.internalState.qrEncodableString == rhs.internalState.qrEncodableString
    }

    var internalState: any QRCodeTypeState
}

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
