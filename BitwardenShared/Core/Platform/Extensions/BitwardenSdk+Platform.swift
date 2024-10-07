// swiftlint:disable:this file_name

import BitwardenSdk
import Foundation

extension BitwardenSdk.BitwardenError: CustomNSError {
    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
        guard case let .E(message) = self else {
            return [:]
        }
        return ["Message": message]
    }
}
