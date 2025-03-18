import BitwardenSdk

/// An object that defines the current state of a `ViewAsQRCodeView`.
///
struct ViewAsQRCodeState: Equatable {
    var availableCodeTypes: [QRCodeType] = QRCodeType.allCases

    var qrCodeType: QRCodeType = .wifi

    var typeState: any QRCodeTypeState

    var parameters: [QRCodeParameter] {
        typeState.parameters
    }

    static func == (lhs: ViewAsQRCodeState, rhs: ViewAsQRCodeState) -> Bool {
        lhs.availableCodeTypes == rhs.availableCodeTypes
            && lhs.qrCodeType == rhs.qrCodeType
            && lhs.typeState.parameters == rhs.typeState.parameters
    }
}
