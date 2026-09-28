import XCTest
@testable import ShopSavvySDK

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Drives the scheduling methods through the client's real URLSession (via
/// `StubURLProtocol`) and asserts what goes on the wire. The API's `schedule` and
/// `unschedule` handlers read ONLY the query string, so a JSON body is silently ignored and
/// the call fails server-side with a missing-parameter error.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class SchedulingTests: XCTestCase {

    private let scheduleResponse = """
    {
      "success": true,
      "data": [
        { "title": "Keurig K-Mini", "shopsavvy": "3ONn300xybP3y66ibqc1", "barcode": "611247373064",
          "amazon": "B07G14HTBZ", "brand": "Keurig", "category": null, "images": [], "schedule": "daily",
          "retailer": "amazon.com" },
        { "title": "Keurig K-Elite", "shopsavvy": "DrKWneG0MpFlZpwZXNYa", "barcode": "611247369449",
          "amazon": null, "schedule": "daily" }
      ],
      "meta": { "request_id": "req-sched", "credits_used": 2, "credits_remaining": 998, "rate_limit_remaining": 999 }
    }
    """.data(using: .utf8)!

    private let unscheduleResponse = """
    {
      "success": true,
      "message": "Products successfully removed from schedule",
      "meta": { "request_id": "req-unsched", "credits_used": 0, "credits_remaining": 0, "rate_limit_remaining": 0 }
    }
    """.data(using: .utf8)!

    private let scheduledListResponse = """
    {
      "success": true,
      "data": [
        { "title": "Keurig K-Mini", "category": "Coffee Makers", "brand": "Keurig", "color": "Black",
          "shopsavvy": "3ONn300xybP3y66ibqc1", "barcode": "611247373064", "amazon": "B07G14HTBZ",
          "model": "K-Mini", "mpn": null, "images": ["https://images.shopsavvy.com/k-mini.jpg"],
          "title_short": "K-Mini", "slug": "keurig-k-mini",
          "identifiers": { "amazon": "B07G14HTBZ", "upc": "611247373064" },
          "schedule": "hourly", "retailer": "amazon.com" },
        { "title": "Keurig K-Elite", "shopsavvy": "DrKWneG0MpFlZpwZXNYa", "barcode": "611247369449",
          "images": [], "schedule": "weekly" },
        { "title": "Keurig K-Supreme", "shopsavvy": "a1B2c3D4e5F6g7H8i9J0", "barcode": "611247380000",
          "images": [] }
      ],
      "meta": { "request_id": "req-list", "credits_used": 0, "credits_remaining": 0, "rate_limit_remaining": 0 }
    }
    """.data(using: .utf8)!

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

    override func setUp() {
        StubURLProtocol.statusCode = 200
        StubURLProtocol.lastRequest = nil
    }

    /// Returns (method, path, raw percent-encoded query, decoded query items) of the last request,
    /// and asserts no body was sent.
    private func lastRequest(file: StaticString = #filePath, line: UInt = #line) throws -> (String, String, String, [String: String]) {
        let request = try XCTUnwrap(StubURLProtocol.lastRequest, file: file, line: line)
        XCTAssertNil(request.httpBody, "scheduling endpoints read only the query string", file: file, line: line)
        XCTAssertNil(request.httpBodyStream, "scheduling endpoints read only the query string", file: file, line: line)
        let url = try XCTUnwrap(request.url, file: file, line: line)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false), file: file, line: line)
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        return (request.httpMethod ?? "", components.path, components.percentEncodedQuery ?? "", items)
    }

    func testScheduleSingleSendsPutWithQueryParams() async throws {
        StubURLProtocol.responseBody = scheduleResponse
        let response = try await makeClient().scheduleProductMonitoring(identifier: "611247373064", frequency: "daily")

        let (method, path, rawQuery, query) = try lastRequest()
        XCTAssertEqual(method, "PUT")
        XCTAssertEqual(path, "/v1/products/scheduled")
        XCTAssertEqual(rawQuery, "ids=611247373064&schedule=daily")
        XCTAssertEqual(query, ["ids": "611247373064", "schedule": "daily"])

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.data[0].shopsavvy, "3ONn300xybP3y66ibqc1")
        XCTAssertEqual(response.data[0].schedule, "daily")
        XCTAssertEqual(response.data[0].retailer, "amazon.com")
        XCTAssertNil(response.data[0].category)
        XCTAssertNil(response.data[1].amazon)
        XCTAssertNil(response.data[1].retailer)
        XCTAssertEqual(response.meta?.requestId, "req-sched")
        XCTAssertEqual(response.creditsUsed(), 2)
    }

    func testScheduleSingleWithRetailer() async throws {
        StubURLProtocol.responseBody = scheduleResponse
        _ = try await makeClient().scheduleProductMonitoring(identifier: "611247373064", frequency: "hourly", retailer: "amazon.com")

        let (method, path, rawQuery, query) = try lastRequest()
        XCTAssertEqual(method, "PUT")
        XCTAssertEqual(path, "/v1/products/scheduled")
        XCTAssertEqual(rawQuery, "ids=611247373064&schedule=hourly&retailer=amazon.com")
        XCTAssertEqual(query["retailer"], "amazon.com")
    }

    func testScheduleBatchJoinsIdsWithCommasAndEncodes() async throws {
        StubURLProtocol.responseBody = scheduleResponse
        _ = try await makeClient().scheduleProductMonitoringBatch(
            identifiers: ["611247373064", "B07G14HTBZ", "MQ023LL/A"],
            frequency: "weekly"
        )

        let (method, path, rawQuery, query) = try lastRequest()
        XCTAssertEqual(method, "PUT")
        XCTAssertEqual(path, "/v1/products/scheduled")
        XCTAssertEqual(query, ["ids": "611247373064,B07G14HTBZ,MQ023LL/A", "schedule": "weekly"])
        XCTAssertTrue(rawQuery.hasPrefix("ids=611247373064,B07G14HTBZ,MQ023LL/A&schedule=weekly") || rawQuery.hasPrefix("ids=611247373064%2CB07G14HTBZ%2CMQ023LL%2FA&schedule=weekly"), rawQuery)
        XCTAssertNil(query["retailer"])
    }

    func testScheduleBatchWithRetailer() async throws {
        StubURLProtocol.responseBody = scheduleResponse
        _ = try await makeClient().scheduleProductMonitoringBatch(
            identifiers: ["611247373064", "611247369449"],
            frequency: "daily",
            retailer: "bestbuy.com"
        )

        let (method, path, _, query) = try lastRequest()
        XCTAssertEqual(method, "PUT")
        XCTAssertEqual(path, "/v1/products/scheduled")
        XCTAssertEqual(query, ["ids": "611247373064,611247369449", "schedule": "daily", "retailer": "bestbuy.com"])
    }

    func testUnscheduleSingleSendsDeleteWithIdsQuery() async throws {
        StubURLProtocol.responseBody = unscheduleResponse
        let response = try await makeClient().removeProductFromSchedule(identifier: "611247373064")

        let (method, path, rawQuery, query) = try lastRequest()
        XCTAssertEqual(method, "DELETE")
        XCTAssertEqual(path, "/v1/products/scheduled")
        XCTAssertEqual(rawQuery, "ids=611247373064")
        XCTAssertEqual(query, ["ids": "611247373064"])

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Products successfully removed from schedule")
        XCTAssertEqual(response.meta?.requestId, "req-unsched")
    }

    func testUnscheduleBatchJoinsIds() async throws {
        StubURLProtocol.responseBody = unscheduleResponse
        let response = try await makeClient().removeProductsFromScheduleBatch(identifiers: ["611247373064", "611247369449"])

        let (method, path, _, query) = try lastRequest()
        XCTAssertEqual(method, "DELETE")
        XCTAssertEqual(path, "/v1/products/scheduled")
        XCTAssertEqual(query, ["ids": "611247373064,611247369449"])
        XCTAssertTrue(response.success)
    }

    func testScheduleResponseCarriesFullProductFields() async throws {
        StubURLProtocol.responseBody = scheduledListResponse
        let response = try await makeClient().scheduleProductMonitoring(identifier: "611247373064", frequency: "hourly", retailer: "amazon.com")

        let first = response.data[0]
        XCTAssertEqual(first.product.title, "Keurig K-Mini")
        XCTAssertEqual(first.model, "K-Mini")
        XCTAssertNil(first.mpn)
        XCTAssertEqual(first.titleShort, "K-Mini")
        XCTAssertEqual(first.slug, "keurig-k-mini")
        XCTAssertEqual(first.images, ["https://images.shopsavvy.com/k-mini.jpg"])
        XCTAssertNotNil(first.identifiers?["upc"])
        XCTAssertEqual(first.schedule, "hourly")
        XCTAssertEqual(first.retailer, "amazon.com")
    }

    func testScheduledListSendsGetAndDecodesProducts() async throws {
        StubURLProtocol.responseBody = scheduledListResponse
        let response = try await makeClient().getScheduledProducts()

        let request = try XCTUnwrap(StubURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/v1/products/scheduled")
        XCTAssertNil(request.url?.query)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.count, 3)

        XCTAssertEqual(response.data[0].title, "Keurig K-Mini")
        XCTAssertEqual(response.data[0].shopsavvy, "3ONn300xybP3y66ibqc1")
        XCTAssertEqual(response.data[0].barcode, "611247373064")
        XCTAssertEqual(response.data[0].brand, "Keurig")
        XCTAssertEqual(response.data[0].schedule, "hourly")
        XCTAssertEqual(response.data[0].retailer, "amazon.com")

        XCTAssertEqual(response.data[1].shopsavvy, "DrKWneG0MpFlZpwZXNYa")
        XCTAssertEqual(response.data[1].schedule, "weekly")
        XCTAssertNil(response.data[1].retailer)
        XCTAssertNil(response.data[1].brand)

        // Refresh interval with no Data API label: the API omits `schedule`
        XCTAssertEqual(response.data[2].barcode, "611247380000")
        XCTAssertNil(response.data[2].schedule)
        XCTAssertNil(response.data[2].retailer)

        XCTAssertEqual(response.meta?.requestId, "req-list")
        XCTAssertEqual(response.creditsUsed(), 0)
    }

    func testUnscheduleResponseHasNoDataAndDecodesMeta() async throws {
        StubURLProtocol.responseBody = unscheduleResponse
        let response = try await makeClient().removeProductsFromScheduleBatch(identifiers: ["611247373064"])

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.message, "Products successfully removed from schedule")
        XCTAssertEqual(response.meta?.creditsUsed, 0)
        XCTAssertEqual(response.meta?.creditsRemaining, 0)
        XCTAssertEqual(response.meta?.rateLimitRemaining, 0)
    }

    func testScheduledProductRoundTripsFlatShape() throws {
        let item = try JSONDecoder().decode(ApiResponse<[ScheduledProduct]>.self, from: scheduledListResponse).data[0]
        let encoded = try JSONEncoder().encode(item)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(object["shopsavvy"] as? String, "3ONn300xybP3y66ibqc1")
        XCTAssertEqual(object["schedule"] as? String, "hourly")
        XCTAssertEqual(object["retailer"] as? String, "amazon.com")
        XCTAssertNil(object["product"], "product fields are flattened, as on the wire")
        let decoded = try JSONDecoder().decode(ScheduledProduct.self, from: encoded)
        XCTAssertEqual(decoded.barcode, "611247373064")
        XCTAssertEqual(decoded.schedule, "hourly")
    }
}
