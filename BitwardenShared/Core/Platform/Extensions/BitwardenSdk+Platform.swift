// swiftlint:disable:this file_name

import BitwardenSdk
import Foundation

extension BitwardenSdk.BitwardenError: @retroactive CustomNSError {
    /// The user-info dictionary.
    public var errorUserInfo: [String: Any] {
        ["SpecificError": String(describing: self)]
    }
}
