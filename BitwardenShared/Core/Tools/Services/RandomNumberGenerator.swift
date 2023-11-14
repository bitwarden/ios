import Foundation
import Security

// MARK: - RandomNumberGenerator

/// A protocol for an object that can generate random numbers.
///
protocol RandomNumberGenerator {
    /// Generates a random number.
    ///
    /// - Returns: The randomly generated number.
    ///
    func randomNumber() throws -> UInt
}

// MARK: - SecureRandomNumberGenerator

/// An `RandomNumberGenerator` instance which generates secure random numbers.
///
class SecureRandomNumberGenerator: RandomNumberGenerator {
    func randomNumber() throws -> UInt {
        let count = MemoryLayout<UInt>.size
        var bytes = [Int8](repeating: 0, count: count)

        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else { throw CryptoServiceError.randomNumberGenerationFailed(status) }

        return bytes.withUnsafeBytes { pointer in
            pointer.load(as: UInt.self)
        }
    }
}
