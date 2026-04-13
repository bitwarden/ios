# Service Test Example (Swift Testing)

Based on: `BitwardenKit/Core/Vault/Services/TOTP/TOTPServiceErrorTests.swift` and service patterns

```swift
import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DefaultFeatureServiceTests

struct DefaultFeatureServiceTests {
    // MARK: Properties

    let apiService: MockAPIService
    let errorReporter: MockErrorReporter
    let stateService: MockStateService
    let subject: DefaultFeatureService

    // MARK: Initialization

    init() {
        apiService = MockAPIService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DefaultFeatureService(
            apiService: apiService,
            errorReporter: errorReporter,
            stateService: stateService,
        )
    }

    // MARK: Tests

    /// `fetchItems()` returns items from the API on success.
    @Test
    func fetchItems_success_returnsItems() async throws {
        apiService.fetchItemsResult = .success([.fixture()])

        let result = try await subject.fetchItems()

        #expect(result.count == 1)
    }

    /// `fetchItems()` throws when the API returns an error.
    @Test
    func fetchItems_apiError_throws() async {
        apiService.fetchItemsResult = .failure(BitwardenTestError.example)

        await #expect(throws: BitwardenTestError.example) {
            _ = try await subject.fetchItems()
        }
    }

    /// `fetchItems()` logs the error to the error reporter.
    @Test
    func fetchItems_apiError_logsError() async {
        apiService.fetchItemsResult = .failure(BitwardenTestError.example)

        _ = try? await subject.fetchItems()

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }
}
```

## Key Patterns

- No `@MainActor` needed — service tests don't require main actor unless the service dispatches to main
- Dependencies injected **directly** (not via `ServiceContainer.withMocks`) — services use direct constructor injection
- `#expect(throws:)` — replaces `assertAsyncThrows(error:)` helper
- Test success, error throwing, AND side effects (error reporting) separately
- `BitwardenTestError.example` — standard test error fixture
