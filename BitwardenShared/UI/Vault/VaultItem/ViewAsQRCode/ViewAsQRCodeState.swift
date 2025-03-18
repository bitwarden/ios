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
            return cipher.value(of: selectedFields[0]) ?? ""
        case .wifi:
            let ssid = cipher.value(of: selectedFields[0]) ?? "Error"
            let password = cipher.value(of: selectedFields[1]) ?? "Error"
            return "WIFI:T:WPA;S:\(ssid);P:\(password);;"
        }
    }

    var qrCodeType: QRCodeType = .wifi

//    var wifiState: WifiQRCodeState

//    var parameters: [QRCodeParameter2] {
//        switch qrCodeType {
//        case .url:
//            []
//        case .wifi:
//            wifiState.parameters
//        }
//    }

    var typeState: TypeState2

    var expectedFields: [QRCodeParameterOld] {
        qrCodeType.expectedFields
    }

    func fieldsForField(field: QRCodeParameterOld) -> [CipherFieldType] {
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

    func initialSelectedFieldForField(_ field: QRCodeParameterOld, available: [CipherFieldType]) -> CipherFieldType {
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
