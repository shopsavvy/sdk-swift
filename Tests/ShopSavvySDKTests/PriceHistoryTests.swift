import XCTest
@testable import ShopSavvySDK

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Serves a canned HTTP response to the client's real `URLSession`, and records the
/// request it was asked for, so tests exercise the actual request-building and
/// decode path instead of a hand-rolled copy of it.
final class StubURLProtocol: URLProtocol {
    static var responseBody = Data()
    static var statusCode = 200
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        StubURLProtocol.lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: StubURLProtocol.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: StubURLProtocol.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class PriceHistoryTests: XCTestCase {

    private func makeClient() -> ShopSavvyClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return ShopSavvyClient(
            apiKey: "ss_test_valid_key_12345",
            baseURL: "https://api.shopsavvy.com/v1",
            timeoutInterval: 10,
            configuration: configuration
        )
    }

    override func setUpWithError() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "price-history-response", withExtension: "json"))
        StubURLProtocol.responseBody = try Data(contentsOf: url)
        StubURLProtocol.statusCode = 200
        StubURLProtocol.lastRequest = nil
    }

    func testSendsStartAndEndQueryParams() async throws {
        let client = makeClient()
        _ = try await client.getPriceHistory(identifier: "611247373064", startDate: "2022-11-20", endDate: "2022-11-27", retailer: "amazon.com")

        let request = try XCTUnwrap(StubURLProtocol.lastRequest)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/v1/products/offers/history")
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(query["ids"], "611247373064")
        XCTAssertEqual(query["start"], "2022-11-20")
        XCTAssertEqual(query["end"], "2022-11-27")
        XCTAssertEqual(query["retailer"], "amazon.com")
        XCTAssertNil(query["start_date"])
        XCTAssertNil(query["end_date"])
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "ShopSavvy-Swift-SDK/\(VERSION)")
    }

    func testDecodesProductsOffersAndHistoryFromRealShape() async throws {
        let client = makeClient()
        let response = try await client.getPriceHistory(identifier: "611247373064,611247369449", startDate: "2022-11-20", endDate: "2022-11-27")

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.meta?.requestId, "req-7f3c9a")
        XCTAssertEqual(response.creditsUsed(), 14)
        XCTAssertEqual(response.creditsRemaining(), 986)
        XCTAssertEqual(response.meta?.rateLimitRemaining, 999)

        // One entry per product.
        XCTAssertEqual(response.data.count, 2)

        let kMini = response.data[0]
        XCTAssertEqual(kMini.title, "Keurig K-Mini Single Serve Coffee Maker, Black")
        XCTAssertEqual(kMini.shopsavvy, "3ONn300xybP3y66ibqc1")
        XCTAssertEqual(kMini.barcode, "611247373064")
        XCTAssertEqual(kMini.amazon, "B07G14HTBZ")
        XCTAssertEqual(kMini.brand, "Keurig")
        XCTAssertEqual(kMini.model, "K-MINI")
        XCTAssertEqual(kMini.titleShort, "Keurig K-Mini")
        XCTAssertEqual(kMini.images?.count, 1)
        XCTAssertEqual(kMini.offers.count, 2)

        let amazon = kMini.offers[0]
        XCTAssertEqual(amazon.id, "0IUouCFtZEhxeOablTPl")
        XCTAssertEqual(amazon.retailer, "Amazon")
        XCTAssertEqual(amazon.price, 74.96)
        XCTAssertEqual(amazon.currency, "USD")
        XCTAssertEqual(amazon.availability, "in")
        XCTAssertEqual(amazon.condition, "new")
        XCTAssertEqual(amazon.seller, "ACME Deals")
        XCTAssertEqual(amazon.url, "https://www.amazon.com/dp/B07G14HTBZ?m=A1GKQADQC2VI6E")
        XCTAssertEqual(amazon.timestamp, "2022-11-27T22:36:33.236Z")
        XCTAssertEqual(amazon.history.count, 3)

        // Newest first, as the server sorts them.
        XCTAssertEqual(amazon.history[0].timestamp, "2022-11-27T22:36:33.236Z")
        XCTAssertEqual(amazon.history[0].price, 74.96)
        XCTAssertEqual(amazon.history[0].currency, "USD")
        XCTAssertEqual(amazon.history[0].availability, "in")
        XCTAssertEqual(amazon.history[1].price, 70.99)
        XCTAssertEqual(amazon.history[1].availability, "out")
        // An archived point with no recorded currency and unknown availability.
        XCTAssertEqual(amazon.history[2].price, 79.99)
        XCTAssertEqual(amazon.history[2].timestamp, "2022-11-21T08:15:00.000Z")
        XCTAssertNil(amazon.history[2].currency)
        XCTAssertNil(amazon.history[2].availability)

        // Offer with availability omitted and seller explicitly null.
        let bestBuy = kMini.offers[1]
        XCTAssertEqual(bestBuy.id, "Z9kQ2mBestBuyOffer01")
        XCTAssertEqual(bestBuy.retailer, "Best Buy")
        XCTAssertNil(bestBuy.availability)
        XCTAssertNil(bestBuy.seller)
        XCTAssertEqual(bestBuy.price, 59.99)
        XCTAssertEqual(bestBuy.history.map { $0.price }, [59.99, 64.99])

        // Second product: many nullable product fields null, eBay offer with empty history.
        let kElite = response.data[1]
        XCTAssertEqual(kElite.shopsavvy, "DrKWneG0MpFlZpwZXNYa")
        XCTAssertEqual(kElite.barcode, "611247369449")
        XCTAssertNil(kElite.amazon)
        XCTAssertNil(kElite.category)
        XCTAssertNil(kElite.color)
        XCTAssertNil(kElite.mpn)
        XCTAssertEqual(kElite.images, [])
        XCTAssertEqual(kElite.offers.count, 1)
        XCTAssertEqual(kElite.offers[0].retailer, "eBay")
        XCTAssertEqual(kElite.offers[0].condition, "used")
        XCTAssertEqual(kElite.offers[0].history.count, 0)
    }

    func testMissingHistoryAndOffersKeysDecodeAsEmpty() throws {
        let json = """
        { "success": true, "data": [
            { "title": "No offers", "shopsavvy": "p1" },
            { "title": "Offer without history key", "shopsavvy": "p2",
              "offers": [ { "id": "o1", "retailer": "Target", "price": 10.0 } ] }
        ] }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(ApiResponse<[ProductWithPriceHistory]>.self, from: json)
        XCTAssertEqual(response.data[0].offers.count, 0)
        XCTAssertEqual(response.data[1].offers[0].history.count, 0)
        XCTAssertNil(response.meta)
    }

    func testOldFlatOfferModelCannotDecodeRealResponse() throws {
        // Regression guard for the pre-1.3.0 return type: decoding `data` as a flat list
        // of offers fails on a real response, because data[0] is a product (no `id`).
        let data = StubURLProtocol.responseBody
        XCTAssertThrowsError(try JSONDecoder().decode(ApiResponse<[OfferWithHistory]>.self, from: data))
    }
}
