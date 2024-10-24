import Foundation

#if DEBUG
extension URL {
    static let bitwardenAccountSecurity = URL(string: "bitwarden://settings/account_security")!
    static let bitwardenAuthenticatorNewItem = URL(string: "bitwarden://authenticator/newItem")!
    static let bitwardenInvalidPath = URL(string: "bitwarden://unsupported/urll")!
    static let bitwardenSchemeOnly = URL(string: "bitwarden://")!
}
#endif
