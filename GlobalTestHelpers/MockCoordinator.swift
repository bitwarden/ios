import XCTest

@testable import BitwardenShared

enum MockCoordinatorError: Error {
    case alertRouteNotFound
}

class MockCoordinator<Route>: Coordinator {
    var alertShown = [Alert]()
    var contexts: [AnyObject?] = []
    var isLoadingOverlayShowing = false
    var isStarted: Bool = false
    var loadingOverlaysShown = [LoadingOverlayState]()
    var routes: [Route] = []

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

    func start() {
        isStarted = true
    }
}

extension MockCoordinator<AuthRoute> {
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

extension MockCoordinator<SettingsRoute> {
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
