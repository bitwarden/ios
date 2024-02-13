import CoreNFC
import XCTest

@testable import Bitwarden

class DefaultNFCReaderServiceTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultNFCReaderService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultNFCReaderService()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `readerSession(_:didDetectNDEFs:)` parses the NDEF message and publishes an OTP value if it
    /// matches the pattern.
    func test_readerSession_didDetectNDEFs() async throws {
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        let message = try XCTUnwrap(NFCNDEFMessage(
            records: [
                XCTUnwrap(NFCNDEFPayload.wellKnownTypeURIPayload(
                    string: "my.yubico.com/yk/#ccccccjlkgjlevtdernkbbnrrvhcvdbljgchbgbdbvgk"
                )),
            ]
        ))

        subject.readerSession(session, didDetectNDEFs: [message])

        var publisher = try await subject.resultPublisher().makeAsyncIterator()
        let result = try await publisher.next()

        XCTAssertEqual(result, "ccccccjlkgjlevtdernkbbnrrvhcvdbljgchbgbdbvgk")
    }
}

extension DefaultNFCReaderServiceTests: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {}
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}
}
