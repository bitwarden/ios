struct ExpectableField: Equatable, Hashable, Sendable {
    let name: String
    var fieldTitle: String { Localizations.fieldFor(name) }

    let isOptional: Bool
    let fieldPriority: [CipherFieldType]
}

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

    var expectedFields: [ExpectableField] {
        switch self {
        case .wifi:
            [
                ExpectableField(
                    name: Localizations.ssid,
                    isOptional: false,
                    fieldPriority: [
                        .username,
                        .custom(name: "SSID"),
                    ]
                ),
                ExpectableField(
                    name: Localizations.password,
                    isOptional: true,
                    fieldPriority: [.password]
                ),
            ]
        case .url:
            [
                ExpectableField(
                    name: Localizations.url,
                    isOptional: false,
                    fieldPriority: [.uri(index: 0)]
                ),
            ]
        }
    }
}

enum CipherFieldType: Equatable, Menuable, Sendable {
    case none
    case username
    case password
    case notes
    case uri(index: Int)
    case custom(name: String)

    var localizedName: String {
        switch self {
        case .none:
            "--\(Localizations.select)--"
        case .username:
            Localizations.username
        case .password:
            Localizations.password
        case .notes:
            Localizations.notes
        case let .uri(index):
            Localizations.url
        case let .custom(name):
            "Custom field: \(name)"
        }
    }
}
