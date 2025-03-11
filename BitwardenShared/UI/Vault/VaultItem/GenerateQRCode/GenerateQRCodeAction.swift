/// Actions that can be processed by a `GenerateQRCodeProcessor`.
///
enum GenerateQRCodeAction: Equatable {
    /// The QR code type has changed.
    case qrCodeTypeChanged(QRCodeType)
}
