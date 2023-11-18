import UIKit
import UniformTypeIdentifiers

/// A protocol for a service used by the application for sharing data with other apps.
///
protocol PasteboardService: AnyObject {
    /// Copies a string value to the system pasteboard.
    ///
    /// - Parameter string: The string value to copy.
    ///
    func copy(_ string: String)
}

// MARK: - DefaultPasteboardService

/// A default implementation of a `PasteboardService` that uses the system pasteboard for sharing
/// data with other apps.
///
class DefaultPasteboardService: PasteboardService {
    func copy(_ string: String) {
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: string]],
            options: [.localOnly: true]
        )
    }
}
