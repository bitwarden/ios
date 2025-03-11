/// An object that defines the current state of a `ViewAsQRCodeView`.
///
struct ViewAsQRCodeState: Equatable {
    var availableCodeTypes: [QRCodeType] = QRCodeType.allCases

    var string: String

    var qrCodeType: QRCodeType = .wifi
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
