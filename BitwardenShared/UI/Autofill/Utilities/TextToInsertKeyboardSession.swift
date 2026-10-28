// MARK: - TextToInsertKeyboardSession

/// Helpers for managing the keyboard (Remote Text Input) session that backs the AutoFill
/// extension's text-to-insert flow.
///
public enum TextToInsertKeyboardSession {
    // MARK: Static Properties

    /// Whether the text-to-insert flow needs to keep a hidden "anchor" text field focused to keep
    /// the extension's keyboard panel alive.
    ///
    /// **PM-28227:** Before iOS 27, removing or resigning a focused text field (e.g. the master
    /// password field after unlocking, or `UISearchController` resigning) starts a ~5 second timer
    /// that ends the keyboard session and dismisses the extension. A focused anchor field prevents this.
    ///
    /// **PM-40959:** iOS 27 no longer dismisses the extension in those cases. On iOS 27.2, if an
    /// extension text field is focused when the text-to-insert request completes, Safari displays
    /// the inserted text as blank until the field is refocused (an iOS bug). Skipping the anchor on
    /// iOS 27+ avoids keeping a field focused for the whole flow.
    ///
    public static var requiresFocusAnchor: Bool {
        if #available(iOS 27, *) {
            return false
        }
        return true
    }
}
