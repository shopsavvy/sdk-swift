import XCTest
@testable import ShopSavvySDK

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// GET /products/offers carries, per product, an `in_store_prices` array: shelf prices read
/// from shoppers' scanned receipts, labeled `source: "user-collected"`. Decoded through the
/// client's real request and decode path (StubURLProtocol, PriceHistoryTests.swift).
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class InStorePricesTests: XCTestCase {

    private func makeClient() -> ShopSavvyClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return ShopSavvyClient(apiKey: "ss_test_valid_key_12345", baseURL: "https://api.shopsavvy.com/v1", timeoutInterval: 10, configuration: configuration)
    }

    private func fixture() throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "offers-in-store-response", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    func testDecodesUserCollectedInStorePrices() async throws {
        StubURLProtocol.responseBody = try fixture()
        StubURLProtocol.statusCode = 200
        let response = try await makeClient().getCurrentOffers(identifier: "011110838360")
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.path, "/v1/products/offers")
        let product = try XCTUnwrap(response.data.first)
        let inStore = try XCTUnwrap(product.inStorePrices.first)
        XCTAssertEqual(inStore.source, "user-collected")
        XCTAssertEqual(inStore.retailer, "Kroger")
        XCTAssertEqual(inStore.store.address, "1014 Vine St, Cincinnati, OH 45202, USA")
        XCTAssertEqual(inStore.store.latitude, 39.1086)
        XCTAssertEqual(inStore.price, 3.49)
        XCTAssertEqual(inStore.observedOn, "2026-11-07")
        XCTAssertEqual(product.offers.first?.retailer, "Walmart")
    }

    func testInStorePricesAreEmptyWhenOmitted() async throws {
        var body = try XCTUnwrap(JSONSerialization.jsonObject(with: try fixture()) as? [String: Any])
        var data = try XCTUnwrap(body["data"] as? [[String: Any]])
        data[0].removeValue(forKey: "in_store_prices")
        body["data"] = data
        StubURLProtocol.responseBody = try JSONSerialization.data(withJSONObject: body)
        StubURLProtocol.statusCode = 200
        let response = try await makeClient().getCurrentOffers(identifier: "011110838360")
        XCTAssertEqual(response.data.first?.inStorePrices.count, 0)
    }
}
