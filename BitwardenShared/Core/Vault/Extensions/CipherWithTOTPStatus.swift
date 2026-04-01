import BitwardenSdk
import Foundation

/// A helper protocol to centralize time-based one time password authorization logic.
protocol CipherWithTOTPStatus {
    /// Whether the organization allows time-based one time password usage
    var organizationUseTotp: Bool { get }
}

extension Cipher: CipherWithTOTPStatus {}
extension CipherListView: CipherWithTOTPStatus {}
extension CipherView: CipherWithTOTPStatus {}
