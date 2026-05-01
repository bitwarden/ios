# Mock Generation — Bitwarden iOS

How Sourcery generates mocks for testing.

## Annotation

Add `// sourcery: AutoMockable` as a trailing comment on the protocol declaration line:

```swift
protocol FeatureService: AnyObject { // sourcery: AutoMockable
    func fetchItems() async throws -> [Item]
}
```

This generates `MockFeatureService` in the `Sourcery/Generated/` directory of the target framework.

## Trigger

Mock generation runs automatically as a pre-build phase. To run manually:

```bash
# Requires BUILD_DIR — see script header for how to supply it standalone.
./Scripts/generate-mocks.sh BitwardenShared
./Scripts/generate-mocks.sh AuthenticatorShared
./Scripts/generate-mocks.sh BitwardenKit
./Scripts/generate-mocks.sh AuthenticatorBridgeKit
```

## Generated File Locations

| Framework | Generated Mocks Location |
|-----------|--------------------------|
| BitwardenShared | `BitwardenShared/Sourcery/Generated/` |
| AuthenticatorShared | `AuthenticatorShared/Sourcery/Generated/` |
| BitwardenKit | `BitwardenKit/Sourcery/Generated/` |
| AuthenticatorBridgeKit | `AuthenticatorBridgeKit/Sourcery/Generated/` |

## ServiceContainer.withMocks()

In processor and coordinator tests, use `ServiceContainer.withMocks(...)` to get a pre-populated mock container. Pass only the specific mocks you need to configure:

```swift
services = ServiceContainer.withMocks(
    errorReporter: errorReporter,
    featureService: featureService,
)
```

All other services in the container are automatically populated with their generated mocks.

## Naming Convention

Generated mock: `Mock<ProtocolName>`
- `FeatureService` protocol → `MockFeatureService`
- The `Has<Name>` protocol is NOT mocked; only the service protocol itself is mocked
