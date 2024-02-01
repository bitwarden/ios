import XCTest

@testable import BitwardenShared

enum MockCoordinatorError: Error {
    case alertRouteNotFound
}

class MockCoordinator<Route, Event>: Coordinator {
    var alertShown = [Alert]()
    var contexts: [AnyObject?] = []
    var events = [Event]()
    var isLoadingOverlayShowing = false
    var isStarted: Bool = false
    var loadingOverlaysShown = [LoadingOverlayState]()
    var toastsShown = [String]()
    var routes: [Route] = []

    func handleEvent(_ event: Event, context: AnyObject?) async {
        events.append(event)
        contexts.append(context)
    }

    func hideLoadingOverlay() {
        isLoadingOverlayShowing = false
    }

    func navigate(to route: Route, context: AnyObject?) {
        routes.append(route)
        contexts.append(context)
    }

    func showAlert(_ alert: Alert) {
        alertShown.append(alert)
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        isLoadingOverlayShowing = true
        loadingOverlaysShown.append(state)
    }

    func showToast(_ text: String) {
        toastsShown.append(text)
    }

    func start() {
        isStarted = true
    }
}

extension MockCoordinator<AuthRoute, AuthEvent> {
    func unwrapLastRouteAsAlert(file: StaticString = #file, line: UInt = #line) throws -> Alert {
        guard case let .alert(alert) = routes.last else {
            XCTFail(
                "Expected an `.alert` route, but found \(String(describing: routes.last))",
                file: file,
                line: line
            )
            throw MockCoordinatorError.alertRouteNotFound
        }
        return alert
    }
}

extension MockCoordinator<SettingsRoute, SettingsEvent> {
    func unwrapLastRouteAsAlert(file: StaticString = #file, line: UInt = #line) throws -> Alert {
        guard case let .alert(alert) = routes.last else {
            XCTFail(
                "Expected an `.alert` route, but found \(String(describing: routes.last))",
                file: file,
                line: line
            )
            throw MockCoordinatorError.alertRouteNotFound
        }
        return alert
    }
}

extension MockCoordinator<VaultRoute, AuthAction> {
    func unwrapLastRouteAsAlert(file: StaticString = #file, line: UInt = #line) throws -> Alert {
        guard case let .alert(alert) = routes.last else {
            XCTFail(
                "Expected an `.alert` route, but found \(String(describing: routes.last))",
                file: file,
                line: line
            )
            throw MockCoordinatorError.alertRouteNotFound
        }
        return alert
    }
}

extension MockCoordinator<VaultItemRoute, VaultItemEvent> {
    func unwrapLastRouteAsAlert(file: StaticString = #file, line: UInt = #line) throws -> Alert {
        guard case let .alert(alert) = routes.last else {
            XCTFail(
                "Expected an `.alert` route, but found \(String(describing: routes.last))",
                file: file,
                line: line
            )
            throw MockCoordinatorError.alertRouteNotFound
        }
        return alert
    }
}
