// MARK: - AgentAccessHomeEffect

/// Effects that can be processed by an `AgentAccessHomeProcessor`.
///
enum AgentAccessHomeEffect: Equatable {
    /// The view appeared and the saved values need to be loaded.
    case appeared

    /// The app became active again, so the notification status may have changed.
    case refreshNotificationStatus

    /// Stop an automatic approval.
    ///
    /// - Parameter id: The ID of the rule to remove.
    ///
    case removeRule(id: String)

    /// Go back to the default relay server.
    case resetRelayURL

    /// Save the relay server address.
    case saveRelayURL

    /// Turn listening for agent requests on or off.
    ///
    /// - Parameter enabled: Whether listening should be on.
    ///
    case setListening(Bool)

    /// Start listening for connection status changes.
    case streamStatus

    /// Ask for notification permission, or open iOS Settings if it was denied.
    case turnOnNotifications
}
