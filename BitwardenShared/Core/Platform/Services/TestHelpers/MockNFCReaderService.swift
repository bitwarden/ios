import Combine

@testable import BitwardenShared

class MockNFCReaderService: NFCReaderService {
    var didStartReading = false
    var didStopReading = false
    var resultSubject = CurrentValueSubject<String?, Error>(nil)
    var supportsNFC = false

    func resultPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<String?, Error>> {
        resultSubject.eraseToAnyPublisher().values
    }

    func startReading() {
        didStartReading = true
    }

    func stopReading() {
        didStopReading = true
    }
}
