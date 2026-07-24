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

    /// The number of hours from creation the user is required to use as the Send deletion date, or
    /// `nil` if the deletion date is unrestricted.
    var enforcedDeletionDateHours: Int?

    /// The Send type the user is required to use, or `nil` if both types are allowed (unrestricted).
    var enforcedSendType: SendType?

    /// Whether the hide-email option is disabled.
    var isHideEmailDisabled = false

    /// Whether creating and editing Sends is disabled.
    var isSendDisabled = false
}

extension SendPolicyOptions {
    /// Creates the Send policy options from the Send Controls policies that apply to the user.
    ///
    /// When multiple policies apply, a restriction is enforced if *any* applying policy enables it.
    /// Additionally:
    /// - The enforced access type is resolved to the most restrictive across all applying policies
    ///   (email verification > password protection > no access control).
    /// - The enforced access control (`whoCanAccess`) values are ordered by restrictiveness and the
    ///   highest value wins.
    /// - The enforced Send type is the most restrictive across all applying policies (per the order
    ///   text > file > both/unrestricted).
    /// - The enforced deletion date is the most restrictive (shortest timeframe, i.e. the minimum
    ///   number of hours) across all applying policies.
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
            enforcedDeletionDateHours: policies.compactMap { $0[.deletionHours]?.intValue }.min(),
            enforcedSendType: Self.enforcedSendType(from: policies),
            isHideEmailDisabled: policies.contains { $0[.disableHideEmail]?.boolValue == true },
            isSendDisabled: policies.contains { $0[.disableSend]?.boolValue == true },
        )
    }

    /// Determines the Send type the user is restricted to from the applying `sendControls` policies.
    ///
    /// The server sends `allowedSendTypes` as an array of `SendType` raw values (`0` = text,
    /// `1` = file); a policy restricts the type when it allows exactly one type. When multiple
    /// policies apply, the most restrictive wins per the order text > file > both/unrestricted.
    ///
    /// - Parameter policies: The `sendControls` policies applying to the active user.
    /// - Returns: The enforced `SendType`, or `nil` if both types are allowed (unrestricted).
    ///
    private static func enforcedSendType(from policies: [Policy]) -> SendType? {
        let restrictedTypes = policies.compactMap { policy -> SendType? in
            guard let rawTypes = policy[.allowedSendTypes]?.arrayValue else { return nil }
            let allowedTypes = Set(rawTypes.compactMap(\.intValue).compactMap(SendType.init(rawValue:)))
            return allowedTypes.count == 1 ? allowedTypes.first : nil
        }

        if restrictedTypes.contains(.text) { return .text }
        if restrictedTypes.contains(.file) { return .file }
        return nil
    }
}
