import Foundation

extension Data {
    /// A 16x16 HEIC image, for use in tests.
    static var testHeic: Data {
        Data(
            base64Encoded: """
            AAAAJGZ0eXBoZWljAAAAAG1pZjFNaVBybWlhZk1pSEJoZWljAAABhm1ldGEAAAAAAAAAIWhkbHIAAAAAAAAAAHBpY3QAAAAAAAAA
            AAAAAAAAAAAAJGRpbmYAAAAcZHJlZgAAAAAAAAABAAAADHVybCAAAAABAAAADnBpdG0AAAAAAAEAAAAjaWluZgAAAAAAAQAAABVp
            bmZlAgAAAAABAABodmMxAAAAAOZpcHJwAAAAxWlwY28AAAATY29scm5jbHgAAgACAAaAAAAADGNsbGkAywBAAAAAFGlzcGUAAAAA
            AAAAEAAAABAAAAAJaXJvdAAAAAAQcGl4aQAAAAADCAgIAAAAcWh2Y0MBA3AAAACwAAAAAAAe8AD8/fj4AAALA6AAAQAXQAEMAf//
            A3AAAAMAsAAAAwAAAwAecCShAAEAI0IBAQNwAAADALAAAAMAAAMAHqAUIEHAkwziHuRZVNwICBgCogABAAlEAcBhcshEU2QAAAAZ
            aXBtYQAAAAAAAAABAAEGgQIDBYaEAAAAHmlsb2MAAAAARAAAAQABAAAAAQAAAboAAABfAAAAAW1kYXQAAAAAAAAAbwAAAFsoAa+j
            wIAqk+72J4wTa807BhB+CSI1oyIaZpbn9yvaa+ZHVtv+FmtVkFKnMOJCQ5TB4oSAGdf3n//pk945QAf+XWMBmgj+gDYbSH//msI8
            dss4+n0ujWtgfT/4
            """,
            options: .ignoreUnknownCharacters,
        )!
    }

    /// A 1x1 WebP image, for use in tests.
    static var testWebP: Data {
        Data(base64Encoded: "UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA")!
    }
}
