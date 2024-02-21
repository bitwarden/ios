import Combine

// MARK: _ NFCReaderServiceError

/// An enumeration of errors thrown by `NFCReaderService`.
///
enum NFCReaderServiceError: Error {
    /// NFC is not supported.
    case nfcNotSupported
}

// MARK: - NFCReaderService

/// A protocol for a service which can read NFC tags.
///
public protocol NFCReaderService: AnyObject {
    /// A publisher that publishes a new value when an NFC tag is read.
    ///
    func resultPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<String?, Error>>

    /// Starts the process of reading NFC tags.
    ///
    func startReading()

    /// Stops the process of reading NFC tags.
    ///
    func stopReading()
}

// MARK: - NFCReaderService

/// A no-op version of `NFCReaderService` for use in app extensions which don't have NFC capabilities.
///
class NoopNFCReaderService: NFCReaderService {
    func resultPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<String?, Error>> {
        throw NFCReaderServiceError.nfcNotSupported
    }

    func startReading() {}

    func stopReading() {}
}
