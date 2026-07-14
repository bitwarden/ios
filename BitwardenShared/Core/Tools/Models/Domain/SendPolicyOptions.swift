import Foundation

// MARK: - SendPolicyOptions

/// The set of Send restrictions enforced by the Send Controls policy for the active user.
///
struct SendPolicyOptions: Equatable, Sendable {
    // MARK: Properties

    /// The domains that recipient emails must match when email verification ("Specific people") is
    /// the enforced access type. Empty when there is no domain restriction.
    var allowedDomains: [String] = []

    /// The access type the user is required to use, or `nil` if the access type is unrestricted.
    var enforcedAccessType: SendAccessType?

    /// Whether the hide-email option is disabled.
    var isHideEmailDisabled = false

    /// Whether creating and editing Sends is disabled.
    var isSendDisabled = false
}

extension SendPolicyOptions {
    /// Creates the Send policy options from the Send Controls policies that apply to the user.
    ///
    /// When multiple policies apply, a boolean restriction is enforced if *any* applying policy
    /// enables it, and the access type is resolved to the most restrictive across all applying
    /// policies: email verification > password protection > no access control. The `whoCanAccess`
    /// values are ordered by restrictiveness, so the highest value wins.
    ///
    /// - Parameter sendControlsPolicies: The `sendControls` policies applying to the active user.
    ///
    init(sendControlsPolicies policies: [Policy]) {
        let enforcedAccessType = SendAccessType(
            whoCanAccessPolicyValue: policies.compactMap { $0[.whoCanAccess]?.intValue }.max(),
        )

        // Domain restrictions only apply to email verification. When it's enforced, use the domains
        // from the earliest-revision policy that enforces it. The server sends `allowedDomains` as a
        // comma-separated string (e.g. "acme.com, acme.co").
        let domainsPolicy = enforcedAccessType == .specificPeople
            ? policies
                .filter { SendAccessType(whoCanAccessPolicyValue: $0[.whoCanAccess]?.intValue) == .specificPeople }
                .min { ($0.revisionDate ?? .distantFuture) < ($1.revisionDate ?? .distantFuture) }
            : nil
        let allowedDomains = (domainsPolicy?[.allowedDomains]?.stringValue ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        self.init(
            allowedDomains: allowedDomains,
            enforcedAccessType: enforcedAccessType,
            isHideEmailDisabled: policies.contains { $0[.disableHideEmail]?.boolValue == true },
            isSendDisabled: policies.contains { $0[.disableSend]?.boolValue == true },
        )
    }
}
