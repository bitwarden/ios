import Foundation

class AuthenticatorSharedBundleFinder {
    static let bundle = Bundle(for: AuthenticatorSharedBundleFinder.self)
}

public extension Bundle {
    /// The bundle for the `AuthenticatorShared` target.
    static let authenticatorShared = AuthenticatorSharedBundleFinder.bundle
}
