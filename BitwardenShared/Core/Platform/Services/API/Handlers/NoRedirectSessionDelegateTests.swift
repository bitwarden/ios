import Foundation
import XCTest

@testable import BitwardenShared

// MARK: - NoRedirectSessionDelegateTests

class NoRedirectSessionDelegateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: NoRedirectSessionDelegate!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = NoRedirectSessionDelegate()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)` calls the
    /// completion handler with `nil` for 302 responses, preventing the automatic redirect.
    func test_willPerformHTTPRedirection_302_blocksRedirect() {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 302,
            httpVersion: nil,
            headerFields: nil,
        )!
        let newRequest = URLRequest(url: URL(string: "https://redirected.example.com")!)

        var capturedRequest: URLRequest? = URLRequest(url: URL(string: "https://sentinel.example.com")!)
        subject.urlSession(
            session,
            task: task,
            willPerformHTTPRedirection: response,
            newRequest: newRequest,
        ) { request in
            capturedRequest = request
        }

        XCTAssertNil(capturedRequest)
    }

    /// `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)` calls the
    /// completion handler with the new request for non-302 responses, allowing automatic redirect.
    func test_willPerformHTTPRedirection_301_allowsRedirect() {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 301,
            httpVersion: nil,
            headerFields: nil,
        )!
        let newRequest = URLRequest(url: URL(string: "https://redirected.example.com")!)

        var capturedRequest: URLRequest?
        subject.urlSession(
            session,
            task: task,
            willPerformHTTPRedirection: response,
            newRequest: newRequest,
        ) { request in
            capturedRequest = request
        }

        XCTAssertEqual(capturedRequest, newRequest)
    }

    /// `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)` calls the
    /// completion handler with the new request for 303 responses, allowing automatic redirect.
    func test_willPerformHTTPRedirection_303_allowsRedirect() {
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: URL(string: "https://example.com")!)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 303,
            httpVersion: nil,
            headerFields: nil,
        )!
        let newRequest = URLRequest(url: URL(string: "https://redirected.example.com")!)

        var capturedRequest: URLRequest?
        subject.urlSession(
            session,
            task: task,
            willPerformHTTPRedirection: response,
            newRequest: newRequest,
        ) { request in
            capturedRequest = request
        }

        XCTAssertEqual(capturedRequest, newRequest)
    }
}
