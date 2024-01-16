import Foundation

enum CipherMock {
    static let ciphers: [CipherDTO] = [
        CipherDTO(
            id: "0",
            login: LoginDTO(
                totp: "otpauth://account?period=10&secret=LLLLLLLLLLLLLLLL",
                uris: cipherLoginUris,
                username: "test@testing.com"
            ),
            name: "MySite",
            userId: "123123"
        ),
        CipherDTO(
            id: "1",
            login: LoginDTO(
                totp: "LLLLLLLLLLLLLLLL",
                uris: cipherLoginUris,
                username: "thisisatest@testing.com"
            ),
            name: "GitHub",
            userId: "123123"
        ),
        CipherDTO(
            id: "2",
            login: LoginDTO(
                totp: "otpauth://account?period=10&digits=8&algorithm=sha256&secret=LLLLLLLLLLLLLLLL",
                uris: cipherLoginUris,
                username: nil
            ),
            name: "No user",
            userId: "123123"
        ),
        CipherDTO(
            id: "3",
            login: LoginDTO(
                totp: "otpauth://account?period=10&digits=7&algorithm=sha512&secret=LLLLLLLLLLLLLLLL",
                uris: cipherLoginUris,
                username: "longtestemail000000@fastmailasdfasdf.com"
            ),
            name: "Site 2",
            userId: "123123"
        ),
        CipherDTO(
            id: "4",
            login: LoginDTO(
                totp: "steam://LLLLLLLLLLLLLLLL",
                uris: cipherLoginUris,
                username: "user3"
            ),
            name: "Really long name for a site that is used for a totp",
            userId: "123123"
        ),
        CipherDTO(
            id: "5",
            login: LoginDTO(
                totp: "steam://LLLLLLLLLLLLLLLL",
                uris: cipherLoginUris,
                username: "u"
            ),
            name: "Short",
            userId: "123123"
        ),
    ]

    static let cipherLoginUris: [LoginUriDTO] = [
        LoginUriDTO(uri: "github.com"),
        LoginUriDTO(uri: "example2.com"),
    ]
}
