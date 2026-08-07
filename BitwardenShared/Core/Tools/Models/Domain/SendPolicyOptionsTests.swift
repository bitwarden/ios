import BitwardenKit
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SendPolicyOptionsTests

struct SendPolicyOptionsTests {
    // MARK: init(sendControlsPolicies:) Tests

    /// `init(sendControlsPolicies:)` disables the hide email option when a policy enables the
    /// `disableHideEmail` option.
    @Test
    func init_sendControlsPolicies_disableHideEmail() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(data: [PolicyOptionType.disableHideEmail.rawValue: .bool(true)], type: .sendControls),
        ])
        #expect(subject.isHideEmailDisabled)
    }

    /// `init(sendControlsPolicies:)` disables Sends when a policy enables the `disableSend` option.
    @Test
    func init_sendControlsPolicies_disableSend() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(data: [PolicyOptionType.disableSend.rawValue: .bool(true)], type: .sendControls),
        ])
        #expect(subject.isSendDisabled)
    }

    /// `init(sendControlsPolicies:)` enforces no restrictions when there are no applying policies.
    @Test
    func init_sendControlsPolicies_empty() {
        let subject = SendPolicyOptions(sendControlsPolicies: [])
        #expect(!subject.isHideEmailDisabled)
        #expect(!subject.isSendDisabled)
    }

    /// `init(sendControlsPolicies:)` enforces a restriction when *any* applying policy enables it.
    @Test
    func init_sendControlsPolicies_multiplePolicies_enforcesIfAny() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(data: [PolicyOptionType.disableSend.rawValue: .bool(false)], id: "a", type: .sendControls),
            .fixture(data: [PolicyOptionType.disableSend.rawValue: .bool(true)], id: "b", type: .sendControls),
        ])
        #expect(subject.isSendDisabled)
    }
}
