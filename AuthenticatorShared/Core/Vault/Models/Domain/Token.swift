import Foundation

/// Data model for an OTP token
///
public struct Token: Equatable, Sendable {
    // MARK: Properties

    let id: String

    let key: TOTPKeyModel

    let name: String

    // MARK: Initialization

    init?(
        id: String = UUID().uuidString,
        name: String,
        authenticatorKey: String
    ) {
        guard let keyModel = TOTPKeyModel(authenticatorKey: authenticatorKey)
        else { return nil }

        self.id = id
        self.name = name
        key = keyModel
    }
}
