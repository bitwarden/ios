import BitwardenSdk
import Foundation

/// The state of an `EditTokenView`
protocol EditTokenState: Sendable {
    // MARK: Properties

    /// The account of the token
    var account: String { get set }

    /// The Add or Existing Configuration.
    var configuration: TokenItemState.Configuration { get }

    /// A flag indicating if the key is visible.
    var isKeyVisible: Bool { get set }

    /// The issuer of the token
    var issuer: String { get set }

    /// The name of this item.
    var name: String { get set }

    /// A toast for views
    var toast: Toast? { get set }

    /// The TOTP key/code state.
    var totpState: LoginTOTPState { get set }
}
