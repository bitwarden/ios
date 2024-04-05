import Foundation

/// Data model for an OTP token
///
public struct Token: Equatable, Sendable {
    // MARK: Properties

    let id: String

    let key: TOTPKeyModel

    let name: String

    // MARK: Initialization

    init?(name: String, authenticatorKey: String) {
        guard let keyModel = TOTPKeyModel(authenticatorKey: authenticatorKey)
        else { return nil }

        id = UUID().uuidString
        self.name = name
        key = keyModel
    }
}
