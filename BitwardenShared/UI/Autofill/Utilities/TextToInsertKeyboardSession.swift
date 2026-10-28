// MARK: - TextToInsertKeyboardSession

/// Helpers for managing the keyboard (Remote Text Input) session that backs the AutoFill
/// extension's text-to-insert flow.
///
public enum TextToInsertKeyboardSession {
    // MARK: Static Properties

    /// Whether all extension text field focus (including the PM-28227 keyboard anchors) should be
    /// released when the user taps an item to insert, before the request completes.
    ///
    /// **PM-28227:** A hidden anchor text field stays focused for the text-to-insert flow so the
    /// keyboard panel isn't dismissed when a focused text field is removed (e.g. after unlocking).
    ///
    /// **PM-40959:** On iOS 27, if an extension text field is focused when the text-to-insert
    /// request completes, Safari displays the inserted text as blank until the field is refocused
    /// (an iOS bug). Releasing focus when an item is tapped means no field is focused by the time
    /// the user picks which value to insert. iOS 27 no longer dismisses the panel when the anchor's
    /// focus is released.
    ///
    public static var releasesFocusOnItemTap: Bool {
        if #available(iOS 27, *) {
            return true
        }
        return false
    }
}
