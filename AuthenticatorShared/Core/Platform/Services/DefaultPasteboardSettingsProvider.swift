import BitwardenKit

/// Authenticator clipboard preferences backed by the device settings store.
class DefaultPasteboardSettingsProvider: PasteboardSettingsProvider {
    // MARK: Properties

    var allowUniversalClipboard: Bool { appSettingsStore.allowUniversalClipboard }
    private(set) var clearClipboardValue: ClearClipboardValue = .never

    private let appSettingsStore: AppSettingsStore

    // MARK: Initialization

    /// Creates a provider backed by the device settings store.
    init(appSettingsStore: AppSettingsStore) {
        self.appSettingsStore = appSettingsStore
    }

    // MARK: Methods

    func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool) {
        appSettingsStore.allowUniversalClipboard = allowUniversalClipboard
    }

    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue) {
        self.clearClipboardValue = clearClipboardValue
    }
}
