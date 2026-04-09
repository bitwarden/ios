import Foundation

class AuthenticatorSharedMocksBundleFinder {
    static let bundle = Bundle(for: AuthenticatorSharedMocksBundleFinder.self)
}

public extension Bundle {
    /// The bundle for the `AuthenticatorSharedMocks` target.
    static let authenticatorSharedMocks = AuthenticatorSharedMocksBundleFinder.bundle
}
