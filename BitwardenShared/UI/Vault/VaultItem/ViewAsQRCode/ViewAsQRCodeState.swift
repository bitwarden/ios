import BitwardenSdk

/// An object that defines the current state of a `ViewAsQRCodeView`.
///
struct ViewAsQRCodeState: Equatable {
    var availableCodeTypes: [QRCodeType] = QRCodeType.allCases

    var qrCodeType: QRCodeType = .wifi

    var typeState: TypeState2

    var parameters: [QRCodeParameter] {
        typeState.internalState.parameters
    }
}
