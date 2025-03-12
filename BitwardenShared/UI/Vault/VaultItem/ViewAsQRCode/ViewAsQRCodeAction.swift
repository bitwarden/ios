/// Actions that can be processed by a `ViewAsQRCodeProcessor`.
///
enum ViewAsQRCodeAction: Equatable {
    /// The QR code type has changed.
    case qrCodeTypeChanged(QRCodeType)

    case additionalFieldChanged(CipherFieldType, index: Int)
}
