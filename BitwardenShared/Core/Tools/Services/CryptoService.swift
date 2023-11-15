import Foundation

// MARK: - CryptoServiceError

/// Errors that are thrown from `CryptoService`.
///
enum CryptoServiceError: Error, Equatable {
    /// Generating a random number failed.
    case randomNumberGenerationFailed(OSStatus)
}

// MARK: - CryptoService

/// A protocol for a service that handles cryptographic operations.
///
protocol CryptoService: AnyObject {
    /// Returns a randomly generated string of a specified length.
    ///
    /// - Parameter length: The length of the generated string.
    /// - Returns: The randomly generated string.
    ///
    func randomString(length: Int) throws -> String
}

// MARK: - DefaultCryptoService

/// The default implementation of a `CryptoService` which handles cryptographic operations.
///
class DefaultCryptoService: CryptoService {
    // MARK: Properties

    /// The generator used for generating random numbers.
    let randomNumberGenerator: RandomNumberGenerator

    /// A string containing the possible characters used for generating a random string.
    let randomStringCharacters = "abcdefghijklmnopqrstuvwxyz1234567890"

    // MARK: Initialization

    /// Initialize a `DefaultCryptoService`.
    ///
    /// - Parameter randomNumberGenerator: The generator used for generating random numbers.
    ///
    init(randomNumberGenerator: RandomNumberGenerator) {
        self.randomNumberGenerator = randomNumberGenerator
    }

    // MARK: CryptoService

    func randomString(length: Int) throws -> String {
        let characters = try (0 ..< length).map { _ in
            let randomOffset = try randomNumber(min: 0, max: randomStringCharacters.count - 1)
            let randomIndex = randomStringCharacters.index(randomStringCharacters.startIndex, offsetBy: randomOffset)
            return randomStringCharacters[randomIndex]
        }
        return String(characters)
    }

    // MARK: Private

    /// Generates a random number within a range.
    ///
    /// - Parameters:
    ///   - min: The minimum number in the range of possible random numbers.
    ///   - max: The maximum number in the range of possible random numbers.
    /// - Returns: A random number within the range.
    ///
    func randomNumber(min: Int, max: Int) throws -> Int {
        // Make max inclusive.
        let max = max + 1

        let diff = UInt(max - min)
        let upperBound = UInt.max / diff * diff
        var randomNumber: UInt
        repeat {
            randomNumber = try randomNumberGenerator.randomNumber()
        } while randomNumber >= upperBound

        return min + Int(randomNumber % diff)
    }
}
