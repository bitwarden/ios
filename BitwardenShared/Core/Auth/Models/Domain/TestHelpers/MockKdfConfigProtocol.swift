import BitwardenSdk

@testable import BitwardenShared

// TODO: BIT-104 Remove this object and update the KdfConfigProtocolTests to use `KdfConfig` instead.

struct MockKdfConfigProtocol: KdfConfigProtocol {
    var kdf: KdfType
    var kdfIterations: Int
    var kdfMemory: Int?
    var kdfParallelism: Int?
}
