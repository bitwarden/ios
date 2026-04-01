import BitwardenSdk
import Foundation

/// A helper protocol to centralize time-based one time password authorization logic.
protocol CipherWithOrgTOTPStatus {
    /// Whether the organization allows time-based one time password usage
    var organizationUseTotp: Bool { get }
}

extension Cipher: CipherWithOrgTOTPStatus {}
extension CipherListView: CipherWithOrgTOTPStatus {}
extension CipherView: CipherWithOrgTOTPStatus {}
