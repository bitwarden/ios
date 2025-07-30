import Foundation

class IconImageHelper {
    static let shared: IconImageHelper = .init()

    private init() {}

    func getLoginIconImage(_ cipher: CipherDTO) -> String? {
        guard let uris = cipher.login.uris, !uris.isEmpty else {
            return nil
        }

        for u in uris {
            guard var hostname = u.uri, hostname.contains(".") else {
                continue
            }

            if !hostname.contains("://") {
                hostname = "http://\(hostname)"
            }

            if hostname.starts(with: "http") {
                return getIconUrl(hostname)
            }
        }

        return nil
    }

    func getIconUrl(_ uriString: String?) -> String? {
        guard let uriString else {
            return nil
        }

        let hostname = URL.createFullUri(from: uriString)?.host
        return hostname == nil
            ? "\(EnvironmentService.shared.iconsUrl)/icon.png"
            : "\(EnvironmentService.shared.iconsUrl)/\(hostname!)/icon.png"
    }
}
