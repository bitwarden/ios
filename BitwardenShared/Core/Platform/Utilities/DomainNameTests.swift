import XCTest

@testable import BitwardenShared

class DomainNameTests: BitwardenTestCase {
    // MARK: Tests

    let dataSet = """
    com
    co.uk
    com.ai
    *.compute.amazonaws.com
    !city.kobe.jp
    """

    /// `loadDataSet(data:)` loads the data set from a data object.
    func test_loadDataSet() throws {
        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        XCTAssertEqual(
            DomainName.dataSet,
            DomainName.DataSet(
                exceptions: Set(["city.kobe.jp"]),
                normals: Set(["com", "co.uk", "com.ai"]),
                wildcards: Set(["compute.amazonaws.com"])
            )
        )
    }

    /// `loadDataSet(data:)` strips out any whitespace or comment lines.
    func test_loadDataSet_stripsWhitespaceAndComments() throws {
        let dataSet = """

        // Instructions on pulling and using this list can be found at https://publicsuffix.org/list/.

        // ===BEGIN ICANN DOMAINS===

        com
        co.uk
        com.ai

        *.compute.amazonaws.com

        !city.kobe.jp
        """

        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        XCTAssertEqual(
            DomainName.dataSet,
            DomainName.DataSet(
                exceptions: Set(["city.kobe.jp"]),
                normals: Set(["com", "co.uk", "com.ai"]),
                wildcards: Set(["compute.amazonaws.com"])
            )
        )
    }

    /// `parseBaseDomain(url:)` parses the base domain for a URL which matches an exception rule.
    func test_parseBaseDomain_exception() throws {
        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        // Exception: !city.kobe.jp
        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://example.city.kobe.jp"))),
            "example.city.kobe.jp"
        )
        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://sub.example.city.kobe.jp"))),
            "example.city.kobe.jp"
        )
    }

    /// `parseBaseDomain(url:)` handles parsing invalid URLs.
    func test_parseBaseDomain_invalidURL() throws {
        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        try XCTAssertNil(DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "com"))))
        try XCTAssertNil(DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "test"))))
        try XCTAssertNil(DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://"))))
        try XCTAssertNil(DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://example"))))
    }

    /// `parseBaseDomain(url:)` parses the base domain for a URL which matches a normal rule.
    func test_parseBaseDomain_normal() throws {
        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://example.com"))),
            "example.com"
        )
        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://sub.example.com"))),
            "example.com"
        )

        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://example.co.uk"))),
            "example.co.uk"
        )
        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://sub.example.co.uk"))),
            "example.co.uk"
        )
    }

    /// `parseBaseDomain(url:)` parses the base domain for a URL which matches a wildcard rule.
    func test_parseBaseDomain_wildcard() throws {
        // Wildcard: *.compute.amazonaws.com
        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://sub.example.compute.amazonaws.com"))),
            "sub.example.compute.amazonaws.com"
        )
        try XCTAssertEqual(
            DomainName.parseBaseDomain(url: XCTUnwrap(URL(string: "https://foo.sub.example.compute.amazonaws.com"))),
            "sub.example.compute.amazonaws.com"
        )
    }

    /// `parseURL(_:)` parses the URL which matches an exception rule.
    func test_parseURL_exception() throws {
        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        // Exception: !city.kobe.jp
        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://example.city.kobe.jp"))),
            DomainName.DomainNameResult(
                topLevelDomain: "city.kobe.jp",
                secondLevelDomain: "example",
                subDomain: ""
            )
        )
        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://sub.example.city.kobe.jp"))),
            DomainName.DomainNameResult(
                topLevelDomain: "city.kobe.jp",
                secondLevelDomain: "example",
                subDomain: "sub"
            )
        )

        try XCTAssertNil(DomainName.parseURL(XCTUnwrap(URL(string: "https://city.kobe.jp"))))
    }

    /// `parseURL(_:)` parses the URL which matches a normal rule.
    func test_parseURL_normal() throws {
        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://example.com"))),
            DomainName.DomainNameResult(
                topLevelDomain: "com",
                secondLevelDomain: "example",
                subDomain: ""
            )
        )
        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://sub.example.com"))),
            DomainName.DomainNameResult(
                topLevelDomain: "com",
                secondLevelDomain: "example",
                subDomain: "sub"
            )
        )

        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://example.co.uk"))),
            DomainName.DomainNameResult(
                topLevelDomain: "co.uk",
                secondLevelDomain: "example",
                subDomain: ""
            )
        )
        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://sub.example.co.uk"))),
            DomainName.DomainNameResult(
                topLevelDomain: "co.uk",
                secondLevelDomain: "example",
                subDomain: "sub"
            )
        )
    }

    /// `parseURL(_:)` parses the URL which matches a wildcard rule.
    func test_parseURL_wildcard() throws {
        let data = try XCTUnwrap(dataSet.data(using: .utf8))
        try DomainName.loadDataSet(data: data)

        // Wildcard: *.compute.amazonaws.com
        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://sub.example.compute.amazonaws.com"))),
            DomainName.DomainNameResult(
                topLevelDomain: "example.compute.amazonaws.com",
                secondLevelDomain: "sub",
                subDomain: ""
            )
        )
        try XCTAssertEqual(
            DomainName.parseURL(XCTUnwrap(URL(string: "https://foo.sub.example.compute.amazonaws.com"))),
            DomainName.DomainNameResult(
                topLevelDomain: "example.compute.amazonaws.com",
                secondLevelDomain: "sub",
                subDomain: "foo"
            )
        )

        try XCTAssertNil(DomainName.parseURL(XCTUnwrap(URL(string: "https://compute.amazonaws.com"))))
    }
}
