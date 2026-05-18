import BitwardenKit
import BitwardenSdk
import CryptoKit
import Foundation

// MARK: - PasswordHealthProcessor

/// The processor used to manage state and handle actions for the `PasswordHealthView`.
///
final class PasswordHealthProcessor: StateProcessor<
    PasswordHealthState,
    PasswordHealthAction,
    PasswordHealthEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasVaultRepository

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `PasswordHealthProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: PasswordHealthState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PasswordHealthEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        }
    }

    override func receive(_ action: PasswordHealthAction) {
        switch action {
        case .itemPressed:
            break
        }
    }

    // MARK: Private

    /// Loads all vault ciphers, decrypts them fully, and computes the reused password groups.
    ///
    private func loadData() async {
        state.loadingState = .loading(nil)
        do {
            // Collect the current snapshot of all cipher list views.
            var cipherListViews: [CipherListView] = []
            for try await ciphers in try await services.vaultRepository.cipherPublisher() {
                cipherListViews = ciphers
                break
            }

            // Filter to login ciphers that have an id, then fetch their full CipherView
            // (which contains the decrypted password).
            let loginListViews = cipherListViews.filter { $0.type.isLogin && $0.id != nil }
            var loginCipherViews: [(listView: CipherListView, cipherView: CipherView)] = []
            for listView in loginListViews {
                guard let cipherView = try await services.vaultRepository.fetchCipher(withId: listView.id!) else {
                    continue
                }
                loginCipherViews.append((listView: listView, cipherView: cipherView))
            }

            let groups = reusedPasswordGroups(from: loginCipherViews)
            state.loadingState = .data(groups)
        } catch {
            services.errorReporter.log(error: error)
            state.loadingState = .data([])
        }
    }

    /// Computes groups of login ciphers that share the same password.
    ///
    /// Passwords are compared by their SHA256 hash so plaintext passwords are not persisted
    /// or retained as dictionary keys beyond the scope of this function.
    ///
    /// - Parameter pairs: Pairs of `CipherListView` (for display) and `CipherView` (for password access).
    /// - Returns: An array of `ReusedPasswordGroup` values, each containing 2 or more ciphers
    ///     that share the same password, sorted by descending cipher count.
    ///
    func reusedPasswordGroups(
        from pairs: [(listView: CipherListView, cipherView: CipherView)],
    ) -> [ReusedPasswordGroup] {
        // Keep only ciphers with a non-empty password.
        let withPasswords = pairs.filter { pair in
            guard let password = pair.cipherView.login?.password else { return false }
            return !password.isEmpty
        }

        // Group by the SHA256 hash of the password.
        var grouped = [String: [CipherListView]]()
        for pair in withPasswords {
            guard let password = pair.cipherView.login?.password else { continue }
            let hash = SHA256.hash(data: Data(password.utf8))
                .compactMap { String(format: "%02x", $0) }
                .joined()
            grouped[hash, default: []].append(pair.listView)
        }

        // Keep only groups with 2 or more ciphers.
        return grouped
            .filter { $0.value.count >= 2 }
            .map { hash, listViews in
                ReusedPasswordGroup(
                    id: hash,
                    ciphers: listViews.sorted { $0.name < $1.name },
                )
            }
            .sorted { $0.ciphers.count > $1.ciphers.count }
    }
}
