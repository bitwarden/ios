import BitwardenKit
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SendPolicyOptionsTests

struct SendPolicyOptionsTests {
    // MARK: init(sendControlsPolicies:) Tests

    /// `init(sendControlsPolicies:)` reads the allowed domains from the enforcing policy's
    /// comma-separated `allowedDomains` string, trimming whitespace.
    @Test
    func init_sendControlsPolicies_allowedDomains() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(
                data: [
                    PolicyOptionType.whoCanAccess.rawValue: .int(2),
                    PolicyOptionType.allowedDomains.rawValue: .string("acme.com, acme.co"),
                ],
                type: .sendControls,
            ),
        ])
        #expect(subject.allowedDomains == ["acme.com", "acme.co"])
    }

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

    /// `init(sendControlsPolicies:)` disables Sends when *any* applying policy enables it.
    @Test
    func init_sendControlsPolicies_disableSend_multiplePolicies_enforcesIfAny() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(data: [PolicyOptionType.disableSend.rawValue: .bool(false)], id: "a", type: .sendControls),
            .fixture(data: [PolicyOptionType.disableSend.rawValue: .bool(true)], id: "b", type: .sendControls),
        ])
        #expect(subject.isSendDisabled)
    }

    /// `init(sendControlsPolicies:)` enforces no restrictions when there are no applying policies.
    @Test
    func init_sendControlsPolicies_empty() {
        let subject = SendPolicyOptions(sendControlsPolicies: [])
        #expect(subject.allowedDomains.isEmpty)
        #expect(subject.enforcedAccessType == nil)
        #expect(subject.enforcedSendType == nil)
        #expect(!subject.isHideEmailDisabled)
        #expect(!subject.isSendDisabled)
    }

    /// `init(sendControlsPolicies:)` maps the `whoCanAccess` option to the enforced access type.
    @Test
    func init_sendControlsPolicies_enforcedAccessType() {
        #expect(
            SendPolicyOptions(sendControlsPolicies: [
                .fixture(data: [PolicyOptionType.whoCanAccess.rawValue: .int(1)], type: .sendControls),
            ]).enforcedAccessType == .anyoneWithPassword,
        )
        #expect(
            SendPolicyOptions(sendControlsPolicies: [
                .fixture(data: [PolicyOptionType.whoCanAccess.rawValue: .int(2)], type: .sendControls),
            ]).enforcedAccessType == .specificPeople,
        )
        #expect(
            SendPolicyOptions(sendControlsPolicies: [
                .fixture(data: [PolicyOptionType.whoCanAccess.rawValue: .int(0)], type: .sendControls),
            ]).enforcedAccessType == nil,
        )
        #expect(
            SendPolicyOptions(sendControlsPolicies: [.fixture(type: .sendControls)]).enforcedAccessType == nil,
        )
    }

    /// `init(sendControlsPolicies:)` resolves the access type to the most restrictive across all
    /// applying policies — email verification beats password protection regardless of revision date.
    @Test
    func init_sendControlsPolicies_enforcedAccessType_emailVerificationBeatsPassword() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(
                data: [PolicyOptionType.whoCanAccess.rawValue: .int(1)],
                id: "password-later",
                revisionDate: Date(year: 2024, month: 6, day: 1),
                type: .sendControls,
            ),
            .fixture(
                data: [PolicyOptionType.whoCanAccess.rawValue: .int(2)],
                id: "email-earlier",
                revisionDate: Date(year: 2024, month: 1, day: 1),
                type: .sendControls,
            ),
        ])
        #expect(subject.enforcedAccessType == .specificPeople)
    }

    /// `init(sendControlsPolicies:)` enforces password protection over no access control.
    @Test
    func init_sendControlsPolicies_enforcedAccessType_passwordBeatsNoAccessControl() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(data: [PolicyOptionType.whoCanAccess.rawValue: .int(0)], id: "none", type: .sendControls),
            .fixture(data: [PolicyOptionType.whoCanAccess.rawValue: .int(1)], id: "password", type: .sendControls),
        ])
        #expect(subject.enforcedAccessType == .anyoneWithPassword)
    }

    /// `init(sendControlsPolicies:)` takes the allowed domains from the earliest-revision policy when
    /// multiple policies enforce email verification.
    @Test
    func init_sendControlsPolicies_allowedDomains_multipleEmailPolicies_earliestRevisionWins() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(
                data: [
                    PolicyOptionType.whoCanAccess.rawValue: .int(2),
                    PolicyOptionType.allowedDomains.rawValue: .string("later.com"),
                ],
                id: "later",
                revisionDate: Date(year: 2024, month: 6, day: 1),
                type: .sendControls,
            ),
            .fixture(
                data: [
                    PolicyOptionType.whoCanAccess.rawValue: .int(2),
                    PolicyOptionType.allowedDomains.rawValue: .string("earlier.com"),
                ],
                id: "earlier",
                revisionDate: Date(year: 2024, month: 1, day: 1),
                type: .sendControls,
            ),
        ])
        #expect(subject.enforcedAccessType == .specificPeople)
        #expect(subject.allowedDomains == ["earlier.com"])
    }

    /// `init(sendControlsPolicies:)` maps a single-element `allowedSendTypes` array to the enforced
    /// Send type.
    @Test
    func init_sendControlsPolicies_enforcedSendType() {
        #expect(
            SendPolicyOptions(sendControlsPolicies: [
                .fixture(data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(0)])], type: .sendControls),
            ]).enforcedSendType == .text,
        )
        #expect(
            SendPolicyOptions(sendControlsPolicies: [
                .fixture(data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(1)])], type: .sendControls),
            ]).enforcedSendType == .file,
        )
    }

    /// `init(sendControlsPolicies:)` enforces no Send type when both types are allowed.
    @Test
    func init_sendControlsPolicies_enforcedSendType_bothAllowed() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(
                data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(0), .int(1)])],
                type: .sendControls,
            ),
        ])
        #expect(subject.enforcedSendType == nil)
    }

    /// `init(sendControlsPolicies:)` enforces no Send type when no policy specifies `allowedSendTypes`.
    @Test
    func init_sendControlsPolicies_enforcedSendType_missing() {
        let subject = SendPolicyOptions(sendControlsPolicies: [.fixture(type: .sendControls)])
        #expect(subject.enforcedSendType == nil)
    }

    /// `init(sendControlsPolicies:)` enforces no Send type when the `allowedSendTypes` array is empty.
    @Test
    func init_sendControlsPolicies_enforcedSendType_emptyArray() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(data: [PolicyOptionType.allowedSendTypes.rawValue: .array([])], type: .sendControls),
        ])
        #expect(subject.enforcedSendType == nil)
    }

    /// `init(sendControlsPolicies:)` enforces the most restrictive Send type across applying
    /// policies (a single-type restriction wins over an unrestricted "both" policy).
    @Test
    func init_sendControlsPolicies_enforcedSendType_multiplePolicies_mostRestrictiveWins() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(
                data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(0), .int(1)])],
                id: "both",
                type: .sendControls,
            ),
            .fixture(
                data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(0)])],
                id: "text-only",
                type: .sendControls,
            ),
        ])
        #expect(subject.enforcedSendType == .text)
    }

    /// `init(sendControlsPolicies:)` enforces the file type when a file-only policy applies
    /// alongside an unrestricted "both" policy.
    @Test
    func init_sendControlsPolicies_enforcedSendType_multiplePolicies_fileOnly() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(
                data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(0), .int(1)])],
                id: "both",
                type: .sendControls,
            ),
            .fixture(
                data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(1)])],
                id: "file-only",
                type: .sendControls,
            ),
        ])
        #expect(subject.enforcedSendType == .file)
    }

    /// `init(sendControlsPolicies:)` resolves a text-only vs file-only conflict to the most
    /// restrictive type (text wins per the order text > file > both).
    @Test
    func init_sendControlsPolicies_enforcedSendType_multiplePolicies_conflictTextWins() {
        let subject = SendPolicyOptions(sendControlsPolicies: [
            .fixture(
                data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(0)])],
                id: "text-only",
                type: .sendControls,
            ),
            .fixture(
                data: [PolicyOptionType.allowedSendTypes.rawValue: .array([.int(1)])],
                id: "file-only",
                type: .sendControls,
            ),
        ])
        #expect(subject.enforcedSendType == .text)
    }
}
