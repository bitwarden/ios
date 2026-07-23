import Foundation

// MARK: - SendPolicyOptions

/// The set of Send restrictions enforced by the Send Controls policy for the active user.
///
struct SendPolicyOptions: Equatable, Sendable {
    // MARK: Properties

    /// Whether the hide-email option is disabled.
    var isHideEmailDisabled = false

    /// Whether creating and editing Sends is disabled.
    var isSendDisabled = false
}

extension SendPolicyOptions {
    /// Creates the Send policy options from the Send Controls policies that apply to the user.
    ///
    /// When multiple policies apply, a restriction is enforced if *any* applying policy enables it.
    ///
    /// - Parameter sendControlsPolicies: The `sendControls` policies applying to the active user.
    ///
    init(sendControlsPolicies policies: [Policy]) {
        self.init(
            isHideEmailDisabled: policies.contains { $0[.disableHideEmail]?.boolValue == true },
            isSendDisabled: policies.contains { $0[.disableSend]?.boolValue == true },
        )
    }
}
