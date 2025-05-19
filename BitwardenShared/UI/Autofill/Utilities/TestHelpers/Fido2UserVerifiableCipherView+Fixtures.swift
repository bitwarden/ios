// swiftlint:disable:this file_name

import BitwardenSdk

@testable import BitwardenShared

struct MockFido2UserVerifiableCipherView: Fido2UserVerifiableCipherView {
    var reprompt: BitwardenSdk.CipherRepromptType

    init(reprompt: BitwardenSdk.CipherRepromptType = .none) {
        self.reprompt = reprompt
    }
}
