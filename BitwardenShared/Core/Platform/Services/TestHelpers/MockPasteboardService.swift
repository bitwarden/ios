import BitwardenKit
@testable import BitwardenShared

class MockPasteboardService: PasteboardService {
    var allowUniversalClipboard: Bool = false
    var clearClipboardValue: ClearClipboardValue = .never
    var copiedString: String?

    func copy(_ string: String) {
        copiedString = string
    }

    func updateAllowUniversalClipboard(_ allowUniversalClipboard: Bool) {
        self.allowUniversalClipboard = allowUniversalClipboard
    }

    func updateClearClipboardValue(_ clearClipboardValue: ClearClipboardValue) {
        self.clearClipboardValue = clearClipboardValue
    }
}
