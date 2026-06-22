import Foundation
import TestHelpers

// swiftlint:disable missing_docs

public extension APITestData {
    // MARK: Fill-Assist Manifest

    static let fillAssistManifest = APITestData(data: Data("""
    {
        "buildId": "v20260611.1",
        "gitSha": "ef5022c3cbd8ea198bf7cb497d71320ed722ae23",
        "maps": {
            "forms": {
                "v1": {
                    "cid": "sha256:3b68ed123425a334166b378bec1ecd0bfab232c21667725b8710d9b35c98f26a",
                    "filename": "forms.v1.json",
                    "schema": "forms.v1.schema.json"
                }
            }
        },
        "timestamp": "2026-06-11T14:29:32.184Z"
    }
    """.utf8))

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
