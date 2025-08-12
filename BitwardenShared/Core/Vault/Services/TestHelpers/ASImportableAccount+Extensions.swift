#if SUPPORTS_CXP

import AuthenticationServices

@available(iOS 26.0, *)
extension ASImportableAccount {
    // MARK: Static methods

    /// Provides a fixture for `ASImportableAccount`
    static func fixture(
        id: Data = Data(capacity: 16),
        userName: String = "",
        email: String = "",
        fullName: String? = nil,
        collections: [ASImportableCollection] = [],
        items: [ASImportableItem] = []
    ) -> ASImportableAccount {
        ASImportableAccount(
            id: id,
            userName: userName,
            email: email,
            fullName: fullName,
            collections: collections,
            items: items
        )
    }

    // MARK: Methods

    /// Dumps the content of the `ASImportableAccount` into lines which can be used with
    /// inline snapshot assertion.
    func dump() -> String { // swiftlint:disable:this function_body_length
        var dumpResult = ""
        dumpResult.append("Email: \(email)\n")
        dumpResult.append("UserName: \(userName)\n")
        dumpResult.append("--- Items ---\n")

        let itemsResult = items.reduce(into: "") { result, item in
            result.appendWithIndentation("Title: \(item.title)\n")
            result.appendWithIndentation("Creation: \(String(describing: item.created))\n")
            result.appendWithIndentation("Modified: \(String(describing: item.lastModified))\n")
            result.appendWithIndentation("--- Credentials ---\n")

            let credentialsResult = item.credentials.reduce(into: "") { credResult, credential in
                switch credential {
                case let .basicAuthentication(basicAuthentication):
                    if let username = basicAuthentication.userName {
                        credResult.appendWithIndentation("Username.FieldType: \(username.fieldType)\n", level: 2)
                        credResult.appendWithIndentation("Username.Value: \(username.value)\n", level: 2)
                    }
                    if let password = basicAuthentication.password {
                        credResult.appendWithIndentation("Password.FieldType: \(password.fieldType)\n", level: 2)
                        credResult.appendWithIndentation("Password.Value: \(password.value)\n", level: 2)
                    }
                case let .passkey(passkey):
                    credResult.appendWithIndentation("CredentialID: \(passkey.credentialID)\n", level: 2)
                    credResult.appendWithIndentation("Key: \(passkey.key)\n", level: 2)
                    credResult.appendWithIndentation(
                        "RelyingPartyIdentifier: \(passkey.relyingPartyIdentifier)\n",
                        level: 2
                    )
                    credResult.appendWithIndentation("UserDisplayName: \(passkey.userDisplayName)\n", level: 2)
                    credResult.appendWithIndentation("Username: \(passkey.userName)\n", level: 2)
                case let .totp(totp):
                    credResult.appendWithIndentation("Algorithm: \(totp.algorithm)\n", level: 2)
                    credResult.appendWithIndentation("Digits: \(totp.digits)\n", level: 2)
                    if let issuer = totp.issuer {
                        credResult.appendWithIndentation("Issuer: \(issuer)\n", level: 2)
                    }
                    credResult.appendWithIndentation("Period: \(totp.period)\n", level: 2)
                    credResult.appendWithIndentation("Secret: \(totp.secret)\n", level: 2)
                    credResult.appendWithIndentation("Username: \(totp.userName ?? "")\n", level: 2)
                case let .note(note):
                    credResult.appendWithIndentation("Note: \(note.content)\n", level: 2)
                case let .creditCard(card):
                    credResult.appendWithIndentation("FullName: \(String(describing: card.fullName))\n", level: 2)
                    credResult.appendWithIndentation("Number: \(String(describing: card.number))\n", level: 2)
                    if let cardType = card.cardType {
                        credResult.appendWithIndentation("CardType: \(cardType)\n", level: 2)
                    }
                    if let expiryDate = card.expiryDate {
                        credResult.appendWithIndentation("ExpiryDate: \(expiryDate)\n", level: 2)
                    }
                    if let validFrom = card.validFrom {
                        credResult.appendWithIndentation("ValidFrom: \(validFrom)\n", level: 2)
                    }
                    if let verificationNumber = card.verificationNumber {
                        credResult.appendWithIndentation("VerificationNumber: \(verificationNumber)\n", level: 2)
                    }
                @unknown default:
                    result.append("unknown default\n")
                }
                if credential != item.credentials.last {
                    credResult.appendWithIndentation("\n\n", level: 2)
                }
            }
            result.append(credentialsResult)
            if item != items.last {
                result.append("\n\n")
            }
        }
        dumpResult.append(itemsResult)
        return dumpResult
    }
}

private extension String {
    mutating func appendWithIndentation(_ other: String, level: Int = 1) {
        let indentation = String(repeating: " ", count: level * 2)
        append("\(indentation)\(other)")
    }
}

#endif
