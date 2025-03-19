import BitwardenSdk

// MARK: - CipherFieldType

/// An enum of the different fields of a cipher that can be used as a parameter for constructing a string
/// to be encoded in a QR code.
enum CipherFieldType: Equatable, Menuable, Sendable {
    case custom(name: String)
    case name
    case none
    case notes
    case password
    case uri(index: Int)
    case username

    var localizedName: String {
        switch self {
        case let .custom(name):
            Localizations.customField(name)
        case .name:
            Localizations.itemName
        case .none:
            "--\(Localizations.select)--"
        case .notes:
            Localizations.notes
        case .password:
            Localizations.password
        case .uri:
            Localizations.websiteURI
        case .username:
            Localizations.username
        }
    }
}

// MARK: CipherView+CipherFieldType

extension CipherView {
    var availableFields: [CipherFieldType] {
        var fieldBuffer: [CipherFieldType] = [.name]

        let possibleFields: [CipherFieldType] = [
            .username,
            .password,
            .notes
        ]

        for field in possibleFields where value(of: field)?.isEmpty == false {
            fieldBuffer.append(field)
        }

        if let urls = login?.uris {
            for index in 0 ..< urls.count {
                fieldBuffer.append(.uri(index: index))
            }
        }

        for customField in customFields {
            fieldBuffer.append(.custom(name: customField.name ?? "Custom Field"))
        }
        return fieldBuffer
    }

    func value(of field: CipherFieldType) -> String? {
        switch field {
        case let .custom(name):
            fields?.first(where: { $0.name == name })?.value
        case .name:
            name
        case .none:
            nil
        case .notes:
            notes
        case .password:
            login?.password
        case let .uri(index):
            login?.uris?[safeIndex: index]?.uri
        case .username:
            login?.username
        }
    }
}
