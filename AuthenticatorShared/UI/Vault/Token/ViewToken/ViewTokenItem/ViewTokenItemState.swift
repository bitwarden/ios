import BitwardenSdk
import Foundation

// MARK: - ViewTokenItemState

// The state for viewing/adding/editing a token item
protocol ViewTokenItemState: Sendable {
    // MARK: Properties

    /// The TOTP key.
    var authenticatorKey: String? { get }

    /// The TOTP key/code state.
//    var totpState: LoginTOTPState
    
    /// The TOTP code model
    var totpCode: TOTPCodeModel? { get }
}

//extension ViewTokenItemState {
//    var totpCode: TOTPCodeModel? {
//        totpState.codeModel
//    }
//}
