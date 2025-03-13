import BitwardenSdk

/// An object that defines the current state of a `ViewAsQRCodeView`.
///
struct ViewAsQRCodeState: Equatable {
    var availableCodeTypes: [QRCodeType] = QRCodeType.allCases

    let cipher: CipherView

    var selectedFields: [CipherFieldType]

    var string: String {
        switch qrCodeType {
        case .url:
            return valueForField(cipher: cipher, field: selectedFields[0]) ?? ""
        case .wifi:
            let ssid = valueForField(cipher: cipher, field: selectedFields[0]) ?? "Error"
            let password = valueForField(cipher: cipher, field: selectedFields[1]) ?? "Error"
            return "WIFI:T:WPA;S:\(ssid);P:\(password);;"
        }
    }

    var qrCodeType: QRCodeType = .wifi

    var expectedFields: [QRCodeParameter] {
        qrCodeType.expectedFields
    }

    func valueForField(cipher: CipherView, field: CipherFieldType) -> String? {
        switch field {
        case .none:
            return nil
        case .username:
            return cipher.login?.username
        case .password:
            return cipher.login?.password
        case .notes:
            return cipher.notes
        case let .uri(index: uriIndex):
            return cipher.login?.uris?[uriIndex].uri
        case let .custom(name: name):
            return cipher.customFields.first(where: {$0.name == name})?.value
        }
    }

    func fieldsForField(field: QRCodeParameter) -> [CipherFieldType] {
        var fieldBuffer = [CipherFieldType]()
        if field.isOptional {
            fieldBuffer.append(.none)
        }
        if cipher.login?.username?.isEmpty == false {
            fieldBuffer.append(.username)
        }
        if cipher.login?.password?.isEmpty == false {
            fieldBuffer.append(.password)
        }
        if cipher.notes?.isEmpty == false {
            fieldBuffer.append(.notes)
        }
        if let urls = cipher.login?.uris {
            for index in 0..<urls.count {
                fieldBuffer.append(.uri(index: index))
            }
        }
        for customField in cipher.customFields {
            fieldBuffer.append(.custom(name: customField.name ?? "Custom Field"))
        }
        return fieldBuffer
    }

    func initialSelectedFieldForField(_ field: QRCodeParameter, available: [CipherFieldType]) -> CipherFieldType {
        for potentialField in field.fieldPriority {
            if available.contains(potentialField) {
                return potentialField
            }
        }
        if available.contains(.none) { return .none }
        return available.first ?? .username
    }

    mutating func setUpInitialSelected() {
        var buffer = [CipherFieldType]()
        for field in qrCodeType.expectedFields {
            let available = fieldsForField(field: field)
            buffer.append(initialSelectedFieldForField(field, available: available))
        }
        selectedFields = buffer
    }
}
