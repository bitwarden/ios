import BitwardenSdk

/// An object that defines the current state of a `ViewAsQRCodeView`.
///
struct ViewAsQRCodeState: Equatable {
    var availableCodeTypes: [QRCodeType] = QRCodeType.allCases

    var parameters: [QRCodeParameter] {
        typeState.parameters
    }

    var qrCodeType: QRCodeType {
        typeState.type
    }

    var qrEncodableString: String {
        typeState.qrEncodableString
    }

    var typeState: any QRCodeTypeState

    static func == (lhs: ViewAsQRCodeState, rhs: ViewAsQRCodeState) -> Bool {
        // We have to specify our own equality in order to handle the existential protocol type
        lhs.availableCodeTypes == rhs.availableCodeTypes
            && lhs.typeState.type == rhs.typeState.type
            && lhs.typeState.parameters == rhs.typeState.parameters
    }
}
