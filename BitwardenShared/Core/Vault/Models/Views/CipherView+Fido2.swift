import BitwardenSdk

/// Extensions for the `BitwardenSdk.CipherView`
extension CipherView {
    /// Whether the cipher has Fido2 credentials or not
    var hasFido2Credentials: Bool {
        guard type == .login, let login else {
            return false
        }
        return login.hasFido2Credentials
    }
}
