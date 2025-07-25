import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - SendListStateTests

class SendListStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `isInfoButtonHidden` is `true` when `type` is `.file`.
    func test_isInfoButtonHidden_fileType() {
        let subject = SendListState(type: .file)
        XCTAssertTrue(subject.isInfoButtonHidden)
    }

    /// `isInfoButtonHidden` is `false` when `type` is `nil`.
    func test_isInfoButtonHidden_nilType() {
        let subject = SendListState(type: nil)
        XCTAssertFalse(subject.isInfoButtonHidden)
    }

    /// `isInfoButtonHidden` is `true` when `type` is `.text`.
    func test_isInfoButtonHidden_textType() {
        let subject = SendListState(type: .text)
        XCTAssertTrue(subject.isInfoButtonHidden)
    }

    /// `navigationTitle` is `File` when `type` is `.file`.
    func test_navigationTitle_fileType() {
        let subject = SendListState(type: .file)
        XCTAssertEqual(subject.navigationTitle, Localizations.file)
    }

    /// `navigationTitle` is `Sends` when `type` is `nil`.
    func test_navigationTitle_nilType() {
        let subject = SendListState(type: nil)
        XCTAssertEqual(subject.navigationTitle, Localizations.send)
    }

    /// `navigationTitle` is `text` when `type` is `.text`.
    func test_navigationTitle_textType() {
        let subject = SendListState(type: .text)
        XCTAssertEqual(subject.navigationTitle, Localizations.text)
    }
}
