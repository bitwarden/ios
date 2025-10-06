//
//  SecretVerificationRequestModel.swift
//  Bitwarden
//
//  Created by Isaiah Inuwa on 2025-10-03.
//


import Foundation
import Networking

struct SecretVerificationRequestModel: JSONRequestBody, Equatable {
    static let encoder = JSONEncoder()

    // MARK: Properties

    let authRequestAccessCode: String?
    let masterPasswordHash: String?
    let otp: String?

    
    init(passwordHash: String) {
        authRequestAccessCode = nil
        masterPasswordHash = passwordHash
        otp = nil
    }
    
    init(otp: String) {
        masterPasswordHash = nil
        self.otp = otp
        authRequestAccessCode = nil
    }
    
    init(accessCode: String) {
        authRequestAccessCode = accessCode
        masterPasswordHash = nil
        otp = nil
    }
}