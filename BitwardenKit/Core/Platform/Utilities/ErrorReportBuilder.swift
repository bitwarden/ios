import Foundation
import MachO // dyld

// MARK: - ErrorReportBuilder

/// A helper object to build error reports to provide detailed error information to share about the
/// error that occurred.
///
public protocol ErrorReportBuilder {
    /// Returns a string containing detailed error information to share about an error that occurred.
    ///
    /// - Parameters:
    ///   - error: The error that occurred to build the error report for.
    ///   - callStack: The call stack to include in the error report.
    /// - Returns: A string containing the details of the error and call stack from where the error
    ///     occurred.
    ///
    func buildShareErrorLog(for error: Error, callStack: String) async -> String
}

// MARK: - DefaultErrorReportBuilder

/// A default implementation of `ErrorReportBuilder` which provides detailed information about an error.
///
public struct DefaultErrorReportBuilder {
    // MARK: Properties

    /// The service used by the application to manage account state.
    private let activeAccountStateProvider: ActiveAccountStateProvider

    /// The service used by the application to get info about the app and device it's running on.
    private let appInfoService: AppInfoService

    // MARK: Initialization

    /// Initialize an `ErrorReportBuilder`.
    ///
    /// - Parameters:
    ///   - activeAccountStateProvider: Object that provides the active account state.
    ///   - appInfoService: The service used by the application to get info about the app
    ///     and device it's running on.
    ///
    public init(
        activeAccountStateProvider: ActiveAccountStateProvider,
        appInfoService: AppInfoService,
    ) {
        self.activeAccountStateProvider = activeAccountStateProvider
        self.appInfoService = appInfoService
    }

    // MARK: Private

    /// Returns a string containing a list of binary images in the app and their start address.
    /// This is needed to symbolicate symbols in the stack trace.
    ///
    private func binaryImageAddresses() -> String {
        // A list of images to match against to filter out of the full list of images.
        let matchingImageNames = [
            "Authenticator",
            "Bitwarden",
        ]

        let imagesCount = _dyld_image_count()
        return (0 ..< imagesCount)
            .compactMap { index in
                guard let header = _dyld_get_image_header(index),
                      let name = _dyld_get_image_name(index),
                      let lastNameComponent = String(cString: name).split(separator: "/").last,
                      matchingImageNames.contains(where: { lastNameComponent.contains($0) })
                else { return nil }

                // Calculate a variable number of spaces to vertically align the header addresses in the output.
                let spaces = String(repeating: " ", count: max(28 - lastNameComponent.count, 1))
                return "\(lastNameComponent):\(spaces)\(header)"
            }
            .joined(separator: "\n")
    }
}

// MARK: DefaultErrorReportBuilder + ErrorReportBuilder

extension DefaultErrorReportBuilder: ErrorReportBuilder {
    public func buildShareErrorLog(for error: Error, callStack: String) async -> String {
        let userId = await (try? activeAccountStateProvider.getActiveAccountId()) ?? "n/a"
        return """
        \(error as NSError)
        \(error.localizedDescription)

        Stack trace:
        \(callStack)

        Binary images:
        \(binaryImageAddresses())

        User ID: \(userId)
        \(appInfoService.appInfoWithoutCopyrightString)
        """
    }
}
