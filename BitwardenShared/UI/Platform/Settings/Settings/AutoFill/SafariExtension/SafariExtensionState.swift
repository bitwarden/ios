// MARK: - SafariExtensionSetupStatus

/// The local setup status for the Safari extension flow.
enum SafariExtensionSetupStatus: Equatable {
    /// The user has not opened the Safari setup flow yet.
    case notStarted

    /// The user opened the Safari setup flow, but iOS could not confirm enablement.
    case setupOpened

    /// The Safari extension was reported enabled by iOS.
    case enabled
}

// MARK: - SafariExtensionState

/// The state used to present the `SafariExtensionView`.
struct SafariExtensionState: Equatable {
    /// The local setup status for the Safari extension.
    var setupStatus: SafariExtensionSetupStatus = .notStarted

    /// Whether the extension setup flow has been opened from Bitwarden.
    var extensionActivated: Bool {
        get { setupStatus != .notStarted }
        set {
            if newValue {
                if setupStatus == .notStarted {
                    setupStatus = .setupOpened
                }
            } else {
                setupStatus = .notStarted
            }
        }
    }

    /// Whether the extension is enabled.
    var extensionEnabled: Bool {
        get { setupStatus == .enabled }
        set {
            if newValue {
                setupStatus = .enabled
            } else {
                setupStatus = extensionActivated ? .setupOpened : .notStarted
            }
        }
    }
}
