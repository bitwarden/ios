import Foundation
import SwiftUI

class CipherDetailsViewModel: ObservableObject {
    @Published var cipher: Cipher

    @Published var totpFormatted: String = ""
    @Published var progress: Double = 1
    @Published var counter: Int
    @Published var iconImageUri: String?

    var key: String
    var period: Int
    var timer: Timer? = nil

    init(cipher: Cipher) {
        self.cipher = cipher
        key = cipher.login.totp!
        period = TotpService.shared.getPeriodFrom(key)
        counter = period
        iconImageUri = IconImageHelper.shared.getLoginIconImage(cipher)
    }

    func startGeneration() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] t in
            guard let self else {
                t.invalidate()
                return
            }

            let epoc = Int64(Date().timeIntervalSince1970)
            let mod = Int(epoc % Int64(period))
            DispatchQueue.main.async {
                self.counter = self.period - mod
                self.progress = Double(self.counter) / Double(self.period)
            }

            if mod == 0 || totpFormatted == "" {
                do {
                    try regenerateTotp()
                } catch {
                    DispatchQueue.main.async {
                        self.totpFormatted = "error"
                        t.invalidate()
                    }
                }
            }
        })
        RunLoop.current.add(timer!, forMode: .common)
        timer?.fire()
    }

    func stopGeneration() {
        timer?.invalidate()
    }

    func regenerateTotp() throws {
        var totpF = try TotpService.shared.GetCodeAsync(key: key) ?? ""
        if totpF.count > 4 {
            let halfIndex = totpF.index(totpF.startIndex, offsetBy: totpF.count / 2)
            totpF = "\(totpF[totpF.startIndex ..< halfIndex]) \(totpF[halfIndex ..< totpF.endIndex])"
        }
        DispatchQueue.main.async {
            self.totpFormatted = totpF
        }
    }
}
