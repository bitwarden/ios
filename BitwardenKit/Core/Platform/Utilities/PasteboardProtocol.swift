import UIKit

// MARK: - PasteboardProtocol

/// A protocol for the system pasteboard. This is used in place of `UIPasteboard` to allow for
/// mocking it during tests, so that the options passed when copying can be verified.
///
public protocol PasteboardProtocol: AnyObject { // sourcery: AutoMockable
    /// Replaces the items on the pasteboard with the specified items and options.
    ///
    /// - Parameters:
    ///   - items: The items to add to the pasteboard.
    ///   - options: The options to apply to the items, such as whether the items should be
    ///     available to other devices and when they should expire.
    ///
    func setItems(_ items: [[String: Any]], options: [UIPasteboard.OptionsKey: Any])
}

// MARK: - UIPasteboard + PasteboardProtocol

extension UIPasteboard: PasteboardProtocol {}
