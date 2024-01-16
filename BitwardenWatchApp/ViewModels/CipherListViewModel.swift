import Combine
import CoreData
import Foundation

class CipherListViewModel: ObservableObject {
    var cipherService: CipherServiceProtocol
    var watchConnectivityManager = WatchConnectivityManager.shared

    @Published private var ciphers: [CipherDTO] = []
    @Published var filteredCiphers: [CipherDTO] = []
    @Published var updateHack: Bool = false
    @Published var showingSheet = false
    @Published var currentState = BWState.valid
    @Published var user: UserDTO?

    @Published var searchTerm: String = ""

    var debugText: String? = nil

    private var subscriber: AnyCancellable?

    init(_ cipherService: CipherServiceProtocol) {
        self.cipherService = cipherService

        subscriber = watchConnectivityManager.watchConnectivitySubject.sink { completion in
            print("WCM subject: \(completion)")
        } receiveValue: { value in
            self.debugText = value.debugText
            self.checkStateAndFetch(value.state)
        }

        Publishers.CombineLatest($ciphers, $searchTerm)
            .map { allCiphers, searchTerm in
                var returnCiphers = allCiphers.filter { c in
                    self.cipherContains(c, searchTerm)
                }

                // WORKAROUND: To display 0 search results
                if !searchTerm.isEmpty,
                   returnCiphers.isEmpty {
                    returnCiphers.append(
                        CipherDTO(
                            id: "-1",
                            login: LoginDTO(
                                totp: "",
                                uris: nil,
                                username: ""
                            ),
                            name: "NoItemsFound"
                        )
                    )
                }

                if searchTerm.isEmpty {
                    self.updateHack = !self.updateHack
                }

                return returnCiphers
            }
            .assign(to: &$filteredCiphers)
    }

    func checkStateAndFetch(_ state: BWState? = nil) {
        guard checkDeviceOwnerAuth() else {
            return
        }

        StateService.shared.checkIntegrity()

        user = StateService.shared.getUser()

        currentState = state ?? StateService.shared.currentState
        showingSheet = currentState != .valid

        if state != nil {
            return
        }

        guard currentState == .valid else {
            ciphers = []
            return
        }

        fetchCiphers()
    }

    func fetchCiphers() {
        let c = cipherService.fetchCiphers(user?.id)
        DispatchQueue.main.async {
            self.ciphers = c
        }
    }

    func cipherContains(_ cipher: CipherDTO, _: String) -> Bool {
        if searchTerm.isEmpty {
            return true
        }

        if cipher.name?.lowercased().contains(searchTerm.lowercased()) ?? false {
            return true
        }

        if cipher.login.username?.lowercased().contains(searchTerm.lowercased()) ?? false {
            return true
        }

        return false
    }

    func checkDeviceOwnerAuth() -> Bool {
        guard KeychainHelper.standard.hasDeviceOwnerAuth() else {
            currentState = .needDeviceOwnerAuth
            showingSheet = true
            StateService.shared.lackedDeviceOwnerAuthLastTime = true
            return false
        }

        if StateService.shared.lackedDeviceOwnerAuthLastTime {
            watchConnectivityManager.triggerSync()
            StateService.shared.lackedDeviceOwnerAuthLastTime = false
        }

        return true
    }
}
