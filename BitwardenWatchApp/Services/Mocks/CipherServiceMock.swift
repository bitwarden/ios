import Foundation

class CipherServiceMock: CipherServiceProtocol {
    func fetchCiphers(_: String?) -> [CipherDTO] {
        ciphers
    }

    func deleteAll(_: String?, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func getCipher(_ id: String) -> CipherDTO? {
        CipherMock.ciphers.first { ci in
            ci.id == id
        }
    }

    func saveCiphers(_: [CipherDTO], completionHandler _: @escaping () -> Void) {}

    private var ciphers = [CipherDTO]()

    init() {
        ciphers = CipherMock.ciphers
    }
}
