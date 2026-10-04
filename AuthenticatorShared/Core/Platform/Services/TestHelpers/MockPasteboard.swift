import UIKit

@testable import AuthenticatorShared

class MockPasteboard: Pasteboard {
    var items: [[String: Any]] = []
    var options: [UIPasteboard.OptionsKey: Any] = [:]

    func setItems(_ items: [[String: Any]], options: [UIPasteboard.OptionsKey: Any]) {
        self.items = items
        self.options = options
    }
}
