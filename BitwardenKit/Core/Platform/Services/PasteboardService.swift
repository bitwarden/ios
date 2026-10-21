import UIKit
import UniformTypeIdentifiers

// MARK: - Pasteboard

/// The pasteboard write operation. This boundary lets tests inspect sharing and expiration options.
public protocol Pasteboard { // sourcery: AutoMockable
    /// Writes items with the specified sharing and expiration options.
    /// - Parameters:
    ///   - items: The items to copy.
    ///   - options: The sharing and expiration policy.
    func setItems(_ items: [[String: Any]], options: [UIPasteboard.OptionsKey: Any])
}

extension UIPasteboard: Pasteboard {}

// MARK: - PasteboardSettingsProvider

/// Supplies the clipboard preferences managed by an application.
public protocol PasteboardSettingsProvider: AnyObject { // sourcery: AutoMockable
    /// Whether copied content can be shared with other devices.
    var allowUniversalClipboard: Bool { get }

    /// The time after which copied content expires.
    var clearClipboardValue: ClearClipboardValue { get }

    /// Updates the Universal Clipboard preference.
    /// - Parameter allowUniversalClipboard: Whether sharing is allowed.
    func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool)

    /// Updates the expiration preference.
    /// - Parameter clearClipboardValue: The expiration period.
    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue)
}

// MARK: - PasteboardService

/// A service for copying text with the user's sharing and expiration preferences.
public protocol PasteboardService: AnyObject { // sourcery: AutoMockable
    /// Whether copied content can be shared with other devices.
    var allowUniversalClipboard: Bool { get }

    /// The time after which copied content expires.
    var clearClipboardValue: ClearClipboardValue { get }

    /// Copies a string to the system pasteboard with the current preferences.
    /// - Parameter string: The string to copy.
    func copy(_ string: String)

    /// Updates the Universal Clipboard preference.
    /// - Parameter allowUniversalClipboard: Whether sharing is allowed.
    func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool)

    /// Updates the expiration preference.
    /// - Parameter clearClipboardValue: The expiration period.
    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue)
}

// MARK: - DefaultPasteboardService

/// The default pasteboard writer shared by both applications.
public class DefaultPasteboardService: PasteboardService {
    // MARK: Properties

    public var allowUniversalClipboard: Bool { settingsProvider.allowUniversalClipboard }
    public var clearClipboardValue: ClearClipboardValue { settingsProvider.clearClipboardValue }

    private let pasteboard: Pasteboard
    private let settingsProvider: PasteboardSettingsProvider
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Creates a pasteboard service using the supplied settings and clock.
    /// - Parameters:
    ///   - pasteboard: The destination pasteboard.
    ///   - settingsProvider: The application's clipboard settings provider.
    ///   - timeProvider: The clock used to calculate expiration.
    public init(
        pasteboard: Pasteboard = UIPasteboard.general,
        settingsProvider: PasteboardSettingsProvider,
        timeProvider: TimeProvider = CurrentTime(),
    ) {
        self.pasteboard = pasteboard
        self.settingsProvider = settingsProvider
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    public func copy(_ string: String) {
        let clearClipboardValue = settingsProvider.clearClipboardValue
        var options: [UIPasteboard.OptionsKey: Any] = [
            .localOnly: !settingsProvider.allowUniversalClipboard,
        ]
        if clearClipboardValue != .never {
            options[.expirationDate] = timeProvider.presentTime.addingTimeInterval(Double(clearClipboardValue.rawValue))
        }
        pasteboard.setItems([[UTType.utf8PlainText.identifier: string]], options: options)
    }

    public func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool) {
        settingsProvider.updateAllowUniversalClipboard(allowUniversalClipboard)
    }

    public func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue) {
        settingsProvider.updateClearClipboardValue(clearClipboardValue)
    }
}
