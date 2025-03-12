/// Actions that can be processed by a `ViewAsQRCodeProcessor`.
///
enum ViewAsQRCodeAction: Equatable {
    /// The QR code type has changed.
    case qrCodeTypeChanged(QRCodeType)

    case wifiSsidFieldChanged(QRCodeFieldReference)

    case wifiPasswordFieldChanged(QRCodeFieldReference)

    case additionalFieldChanged(QRCodeFieldReference, index: Int)
}
