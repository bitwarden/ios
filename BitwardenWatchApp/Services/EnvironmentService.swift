import Foundation

class EnvironmentService {
    static let shared: EnvironmentService = .init()

    let BASE_URL_KEY = "base_url"
    let ICONS_URL_KEY = "icons_url"
    let DEFAULT_ICONS_URL = "https://icons.bitwarden.net"

    private init() {}

    var baseURL: String? {
        get {
            guard let urlData = KeychainHelper.standard.read(BASE_URL_KEY) else {
                return nil
            }

            return String(decoding: urlData, as: UTF8.self)
        }
        set(newUrl) {
            guard let url = newUrl else {
                KeychainHelper.standard.delete(BASE_URL_KEY)
                return
            }
            KeychainHelper.standard.save(url.data(using: .utf8)!, BASE_URL_KEY)
        }
    }

    var iconsUrl: String {
        guard let urlData = KeychainHelper.standard.read(ICONS_URL_KEY) else {
            return baseURL == nil ? DEFAULT_ICONS_URL : "\(baseURL!)/icons"
        }

        return String(decoding: urlData, as: UTF8.self)
    }

    func setIconsUrl(url: String?) {
        guard let url else {
            KeychainHelper.standard.delete(ICONS_URL_KEY)
            return
        }
        KeychainHelper.standard.save(url.data(using: .utf8)!, ICONS_URL_KEY)
    }

    func clear() {
        baseURL = nil
        setIconsUrl(url: nil)
    }
}
