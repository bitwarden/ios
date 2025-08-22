import BitwardenKit
import BitwardenSdk

// MARK: - KdfConfig

/// A model for configuring KDF options.
///
struct KdfConfig: Encodable, Equatable, KdfConfigProtocol {
    // MARK: Properties

    /// The type of kdf used in the request.
    let kdfType: KdfType

    /// The number of kdf iterations performed in the request.
    let kdfIterations: Int

    /// The kdf memory allocated for the computed password hash.
    let kdfMemory: Int?

    /// The number of threads upon which the kdf iterations are performed.
    let kdfParallelism: Int?

    // MARK: Initialization

    /// Initializes a KDF configuration used in the request.
    ///
    /// - Parameters:
    ///   - kdfType: The type of kdf used in the request.
    ///   - kdfIterations: The number of kdf iterations performed in the request.
    ///   - kdfMemory: The kdf memory allocated for the computed password hash.
    ///   - kdfParallelism: The number of threads upon which the kdf iterations are performed.
    ///
    init(
        kdfType: KdfType = .pbkdf2sha256,
        kdfIterations: Int = Constants.pbkdf2Iterations,
        kdfMemory: Int? = nil,
        kdfParallelism: Int? = nil
    ) {
        self.kdfType = kdfType
        self.kdfIterations = kdfIterations
        self.kdfMemory = kdfMemory
        self.kdfParallelism = kdfParallelism
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
                kdfIterations: Int(iterations),
                kdfMemory: Int(memory),
                kdfParallelism: Int(parallelism)
            )
        case let .pbkdf2(iterations):
            self.init(kdfType: .pbkdf2sha256, kdfIterations: Int(iterations))
        }
    }
}

extension KdfConfig {
    /// The KDF type. This maps `kdfType` to `kdf` for conforming to `KdfConfigProtocol`.
    var kdf: KdfType {
        kdfType
    }
}
