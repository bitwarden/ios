import BitwardenResources
import BitwardenShared
import Combine
import CoreNFC
import OSLog

// MARK: - DefaultNFCReaderService

/// A default implementation of `NFCReaderService` which listens for NFC tags using `NFCNDEFReaderSession`.
///
class DefaultNFCReaderService: NSObject, NFCReaderService {
    // MARK: Properties

    /// A reader session for detecting NFC Data Exchange Format (NDEF) tags.
    private var nfcReaderSession: NFCNDEFReaderSession?

    /// A subject to notify any subscribers of scan results.
    private let resultSubject = CurrentValueSubject<String?, Error>(nil)
}

extension DefaultNFCReaderService {
    func resultPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<String?, Error>> {
        resultSubject.eraseToAnyPublisher().values
    }

    func startReading() {
        guard NFCNDEFReaderSession.readingAvailable else { return }
        stopReading()

        nfcReaderSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcReaderSession?.alertMessage = Localizations.holdYubikeyNearTop
        nfcReaderSession?.begin()
    }

    func stopReading() {
        resultSubject.send(nil)
        nfcReaderSession?.invalidate()
        nfcReaderSession = nil
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension DefaultNFCReaderService: NFCNDEFReaderSessionDelegate {
    /// A regex for detecting Yubikey OTPs.
    private var otpPattern: String {
        "^.*?([cbdefghijklnrtuv]{32,64})$"
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                guard let string = String(data: record.payload, encoding: .utf8) else { continue }

                do {
                    let regex = try NSRegularExpression(pattern: otpPattern, options: [])
                    let range = NSRange(string.startIndex ..< string.endIndex, in: string)
                    regex.enumerateMatches(in: string, range: range) { match, _, stop in
                        guard let match,
                              match.numberOfRanges == 2,
                              let matchRange = Range(match.range(at: 1), in: string)
                        else { return }
                        let otp = string[matchRange]
                        resultSubject.send(String(otp))
                        stop.pointee = true
                    }
                } catch {
                    Logger.application.error("DefaultNFCReaderService unable to parse OTP: \(error)")
                }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Logger.application.error("DefaultNFCReaderService error: \(error)")
    }
}
