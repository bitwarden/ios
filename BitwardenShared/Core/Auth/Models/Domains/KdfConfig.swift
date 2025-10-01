import BitwardenKit
import BitwardenSdk

// MARK: - KdfConfig

/// A model for configuring KDF options.
///
struct KdfConfig: Codable, Equatable, Hashable {
    // MARK: Type Properties

    /// The default `KdfConfig` used for new accounts or when upgrading the KDF config to minimums.
    static let defaultKdfConfig = KdfConfig(kdfType: .pbkdf2sha256, iterations: Constants.pbkdf2Iterations)

    // MARK: Properties

    /// The type of KDF used in the request.
    let kdfType: KdfType

    /// The number of KDF iterations performed in the request.
    let iterations: Int

    /// The KDF memory allocated for the computed password hash.
    let memory: Int?

    /// The number of threads upon which the KDF iterations are performed.
    let parallelism: Int?

    // MARK: Initialization

    /// Initializes a KDF configuration used in the request.
    ///
    /// - Parameters:
    ///   - kdfType: The type of KDF used in the request.
    ///   - iterations: The number of KDF iterations performed in the request.
    ///   - memory: The KDF memory allocated for the computed password hash.
    ///   - parallelism: The number of threads upon which the KDF iterations are performed.
    ///
    init(
        kdfType: KdfType = .pbkdf2sha256,
        iterations: Int = Constants.pbkdf2Iterations,
        memory: Int? = nil,
        parallelism: Int? = nil,
    ) {
        self.kdfType = kdfType
        self.iterations = iterations
        self.memory = memory
        self.parallelism = parallelism
    }

    /// Initializes a `KdfConfig` from the SDK's `Kdf` type.
    ///
    /// - Parameter kdf: The type of KDF used in the request.
    ///
    init(kdf: Kdf) {
        switch kdf {
        case let .argon2id(iterations, memory, parallelism):
            self.init(
                kdfType: .argon2id,
                iterations: Int(iterations),
                memory: Int(memory),
                parallelism: Int(parallelism),
            )
        case let .pbkdf2(iterations):
            self.init(kdfType: .pbkdf2sha256, iterations: Int(iterations))
        }
    }
}

// MARK: - KdfConfigProtocol

extension KdfConfig: KdfConfigProtocol {
    var kdf: KdfType {
        kdfType
    }

    var kdfIterations: Int {
        iterations
    }

    var kdfMemory: Int? {
        memory
    }

    var kdfParallelism: Int? {
        parallelism
    }
}
