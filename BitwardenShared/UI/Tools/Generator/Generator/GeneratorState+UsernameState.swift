import BitwardenSdk

extension GeneratorState {
    /// Data model for the values that can be set for generating a username.
    ///
    struct UsernameState: Equatable {
        // MARK: Types

        /// Errors thrown for generating usernames.
        ///
        enum UsernameGeneratorError: Error { // swiftlint:disable:this nesting
            /// A username generation request for a website was required, but no website is present.
            case missingWebsite
        }

        // MARK: Properties

        /// An optional website host used to generate usernames (either plus addressed or catch all).
        var emailWebsite: String?

        /// The type of username to generate.
        var usernameGeneratorType = UsernameGeneratorType.plusAddressedEmail

        // MARK: Catch All Email Properties

        /// The type of value to use when generating a catch-all email.
        var catchAllEmailType: UsernameEmailType = .random

        /// The user's domain for generating catch all emails.
        var domain: String = ""

        // MARK: Forwarded Email Properties

        /// The addy.io API access token to generate a forwarded email alias.
        var addyIOAPIAccessToken: String = ""

        /// The domain name used to generate a forwarded email alias with addy.io.
        var addyIODomainName: String = ""

        /// The base URL for the addy.io api.
        var addyIOSelfHostServerUrl: String = ""

        /// The DuckDuckGo API key used to generate a forwarded email alias.
        var duckDuckGoAPIKey: String = ""

        /// The Fastmail API Key used to generate a forwarded email alias.
        var fastmailAPIKey: String = ""

        /// The Firefox Relay API access token used to generate a forwarded email alias.
        var firefoxRelayAPIAccessToken: String = ""

        /// The service used to generate a forwarded email alias.
        var forwardedEmailService = ForwardedEmailServiceType.addyIO

        /// The ForwardEmail API token used to generate a forwarded email alias.
        var forwardEmailAPIToken: String = ""

        /// The domain name used to generate a forwarded email alias with ForwardEmail.
        var forwardEmailDomainName: String = ""

        /// Whether the service's API key is visible or not.
        var isAPIKeyVisible = false

        /// The simple login API key used to generate a forwarded email alias.
        var simpleLoginAPIKey: String = ""

        /// The base URL for the SimpleLogin api.
        var simpleLoginSelfHostServerUrl: String = ""

        // MARK: Plus Addressed Email Properties

        /// The user's email for generating plus addressed emails.
        var email: String = ""

        /// The type of value to use when generating a plus-addressed email.
        var plusAddressedEmailType: UsernameEmailType = .random

        // MARK: Random Word Properties

        /// Whether to capitalize the random word.
        var capitalize: Bool = false

        /// Whether the random word should include numbers.
        var includeNumber: Bool = false

        // MARK: Methods

        /// Updates the state based on the user's persisted username generation options.
        ///
        /// - Parameter options: The user's saved options.
        ///
        mutating func update(with options: UsernameGenerationOptions) {
            usernameGeneratorType = options.type ?? usernameGeneratorType

            // Catch All Properties
            catchAllEmailType = emailWebsite.isEmptyOrNil ? .random : .website
            domain = options.catchAllEmailDomain ?? domain

            // Forwarded Email Properties
            addyIOAPIAccessToken = options.anonAddyApiAccessToken ?? addyIOAPIAccessToken
            addyIODomainName = options.anonAddyDomainName ?? addyIODomainName
            addyIOSelfHostServerUrl = options.anonAddyBaseUrl ?? addyIOSelfHostServerUrl
            duckDuckGoAPIKey = options.duckDuckGoApiKey ?? duckDuckGoAPIKey
            fastmailAPIKey = options.fastMailApiKey ?? fastmailAPIKey
            firefoxRelayAPIAccessToken = options.firefoxRelayApiAccessToken ?? firefoxRelayAPIAccessToken
            forwardedEmailService = options.serviceType ?? forwardedEmailService
            forwardEmailAPIToken = options.forwardEmailApiToken ?? forwardEmailAPIToken
            forwardEmailDomainName = options.forwardEmailDomainName ?? forwardEmailDomainName
            simpleLoginAPIKey = options.simpleLoginApiKey ?? simpleLoginAPIKey
            simpleLoginSelfHostServerUrl = options.simpleLoginBaseUrl ?? simpleLoginSelfHostServerUrl

            // Plus Address Email Properties
            email = options.plusAddressedEmail ?? email
            plusAddressedEmailType = emailWebsite.isEmptyOrNil ? .random : .website

            // Random Word Properties
            capitalize = options.capitalizeRandomWordUsername ?? capitalize
            includeNumber = options.includeNumberRandomWordUsername ?? includeNumber
        }

        /// Updates the email type value based on current username generator type.
        ///
        /// - Parameter emailType: The email type value to update.
        ///
        mutating func updateEmailType(_ emailType: UsernameEmailType) {
            switch usernameGeneratorType {
            case .plusAddressedEmail:
                plusAddressedEmailType = emailType
            case .catchAllEmail:
                catchAllEmailType = emailType
            case .forwardedEmail,
                 .randomWord:
                // No-op: Email type doesn't exist for these generator types.
                break
            }
        }
    }
}

extension GeneratorState.UsernameState {
    /// Returns whether the inputs for generating the username are valid and a new username can be
    /// generated.
    var canGenerateUsername: Bool {
        switch usernameGeneratorType {
        case .catchAllEmail:
            !domain.isEmpty
        case .plusAddressedEmail,
             .randomWord:
            true
        case .forwardedEmail:
            switch forwardedEmailService {
            case .addyIO:
                [addyIOAPIAccessToken, addyIODomainName].allSatisfy { !$0.isEmpty }
            case .duckDuckGo:
                !duckDuckGoAPIKey.isEmpty
            case .fastmail:
                !fastmailAPIKey.isEmpty
            case .firefoxRelay:
                !firefoxRelayAPIAccessToken.isEmpty
            case .forwardEmail:
                [forwardEmailAPIToken, forwardEmailDomainName].allSatisfy { !$0.isEmpty }
            case .simpleLogin:
                !simpleLoginAPIKey.isEmpty
            }
        }
    }

    /// Returns a `UsernameGenerationOptions` containing the user selected settings for generating
    /// a username used to persist the options between app launches.
    var usernameGenerationOptions: UsernameGenerationOptions {
        UsernameGenerationOptions(
            anonAddyApiAccessToken: addyIOAPIAccessToken.nilIfEmpty,
            anonAddyDomainName: addyIODomainName.nilIfEmpty,
            anonAddyBaseUrl: addyIOSelfHostServerUrl.nilIfEmpty,
            capitalizeRandomWordUsername: capitalize,
            catchAllEmailDomain: domain.nilIfEmpty,
            catchAllEmailType: catchAllEmailType,
            duckDuckGoApiKey: duckDuckGoAPIKey.nilIfEmpty,
            fastMailApiKey: fastmailAPIKey.nilIfEmpty,
            firefoxRelayApiAccessToken: firefoxRelayAPIAccessToken.nilIfEmpty,
            forwardEmailApiToken: forwardEmailAPIToken.nilIfEmpty,
            forwardEmailDomainName: forwardEmailDomainName.nilIfEmpty,
            includeNumberRandomWordUsername: includeNumber,
            plusAddressedEmail: email.nilIfEmpty,
            plusAddressedEmailType: plusAddressedEmailType,
            serviceType: forwardedEmailService,
            simpleLoginApiKey: simpleLoginAPIKey.nilIfEmpty,
            simpleLoginBaseUrl: simpleLoginSelfHostServerUrl.nilIfEmpty,
            type: usernameGeneratorType
        )
    }

    /// Returns a `UsernameGeneratorRequest` containing the user selected settings for generating a
    /// username.
    ///
    func usernameGeneratorRequest() throws -> UsernameGeneratorRequest? {
        guard canGenerateUsername else { return nil }

        return switch usernameGeneratorType {
        case .catchAllEmail:
            try catchAllGeneratorRequest()
        case .forwardedEmail:
            forwardedEmailGeneratorRequest()
        case .plusAddressedEmail:
            try plusAddressedEmailGeneratorRequest()
        case .randomWord:
            UsernameGeneratorRequest.word(capitalize: capitalize, includeNumber: includeNumber)
        }
    }

    // MARK: Private

    /// Returns a `UsernameGeneratorRequest` used to generate a catch-all username.
    ///
    private func catchAllGeneratorRequest() throws -> UsernameGeneratorRequest {
        let type: AppendType
        switch catchAllEmailType {
        case .random:
            type = AppendType.random
        case .website:
            guard let emailWebsite else { throw UsernameGeneratorError.missingWebsite }
            type = AppendType.websiteName(website: emailWebsite)
        }
        return UsernameGeneratorRequest.catchall(type: type, domain: domain)
    }

    /// Returns a `UsernameGeneratorRequest` used to generate a forwarded email alias username.
    ///
    private func forwardedEmailGeneratorRequest() -> UsernameGeneratorRequest {
        let service = switch forwardedEmailService {
        case .addyIO:
            ForwarderServiceType.addyIo(
                apiToken: addyIOAPIAccessToken,
                domain: addyIODomainName,
                baseUrl: addyIOSelfHostServerUrl.nilIfEmpty ?? ForwardedEmailServiceType.defaultAddyIOBaseUrl
            )
        case .duckDuckGo:
            ForwarderServiceType.duckDuckGo(token: duckDuckGoAPIKey)
        case .fastmail:
            ForwarderServiceType.fastmail(apiToken: fastmailAPIKey)
        case .firefoxRelay:
            ForwarderServiceType.firefox(apiToken: firefoxRelayAPIAccessToken)
        case .forwardEmail:
            ForwarderServiceType.forwardEmail(
                apiToken: forwardEmailAPIToken,
                domain: forwardEmailDomainName
            )
        case .simpleLogin:
            ForwarderServiceType.simpleLogin(
                apiKey: simpleLoginAPIKey,
                baseUrl: simpleLoginSelfHostServerUrl.nilIfEmpty
                    ?? ForwardedEmailServiceType.defaultSimpleLoginBaseUrl
            )
        }

        // Fastmail does not allow emailWebsite to be nil.
        let website = (forwardedEmailService == .fastmail) ? (emailWebsite ?? "") : emailWebsite
        return UsernameGeneratorRequest.forwarded(service: service, website: website)
    }

    /// Returns a `UsernameGeneratorRequest` used to generate a plus-addressed email username.
    ///
    private func plusAddressedEmailGeneratorRequest() throws -> UsernameGeneratorRequest {
        let type: AppendType
        switch plusAddressedEmailType {
        case .random:
            type = AppendType.random
        case .website:
            guard let emailWebsite else { throw UsernameGeneratorError.missingWebsite }
            type = AppendType.websiteName(website: emailWebsite)
        }
        return UsernameGeneratorRequest.subaddress(type: type, email: email)
    }
}
