import UIKit

/// Determine the app delegate class that should be used during this launch of the app. If the `TestingAppDelegate`
/// can be found, the app was launched in a test environment, and we should use the `TestingAppDelegate` for
/// handling all app lifecycle events.
private let appDelegateClass: AnyClass = NSClassFromString("TestHarnessTests.TestingAppDelegate") ?? AppDelegate.self

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(appDelegateClass))
