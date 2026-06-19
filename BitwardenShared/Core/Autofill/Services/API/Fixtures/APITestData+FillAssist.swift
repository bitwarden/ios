import Foundation
import TestHelpers

// swiftlint:disable missing_docs

public extension APITestData {
    // MARK: Forms Map

    static let formsMap = APITestData(data: Data("""
    {
        "schemaVersion": "0.1.0",
        "hosts": {
            "example.com": {
                "forms": [
                    {
                        "category": "account-login",
                        "container": ["form#login"],
                        "fields": {
                            "username": ["input#user"],
                            "password": ["input#pass"]
                        },
                        "actions": {
                            "submit": ["button[type=submit]"]
                        }
                    }
                ]
            }
        }
    }
    """.utf8))
}

// swiftlint:enable missing_docs
