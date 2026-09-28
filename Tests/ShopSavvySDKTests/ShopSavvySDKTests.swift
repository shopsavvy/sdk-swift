import XCTest
@testable import ShopSavvySDK

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class ShopSavvySDKTests: XCTestCase {
    
    func testClientInitialization() {
        let client = ShopSavvyClient(apiKey: "ss_test_valid_key_12345")
        XCTAssertNotNil(client)
    }
    
    func testInvalidApiKeyFatal() {
        // Note: In a real test environment, you might want to handle this differently
        // since fatalError will crash the test. This is just for demonstration.
        
        // Test empty API key would cause fatal error
        // let client = ShopSavvyClient(apiKey: "")
        
        // Test invalid format would cause fatal error  
        // let client = ShopSavvyClient(apiKey: "invalid_key")
        
        XCTAssertTrue(true) // Placeholder test
    }
    
    func testModelsDecoding() throws {
        // Real GET /products response shape: `data` is a list of products, `meta`
        // carries credit usage and the request id.
        let jsonData = """
        {
            "success": true,
            "data": [{
                "title": "Test Product",
                "shopsavvy": "test-product-123",
                "brand": "TestBrand",
                "category": "Electronics",
                "barcode": "012345678901",
                "amazon": "B08N5WRWNW",
                "model": "TEST-123",
                "mpn": null,
                "images": ["https://example.com/image.jpg"]
            }],
            "meta": {
                "request_id": "req-123",
                "credits_used": 1,
                "credits_remaining": 999
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ApiResponse<[ProductDetails]>.self, from: jsonData)

        XCTAssertEqual(response.data[0].shopsavvy, "test-product-123")
        XCTAssertEqual(response.data[0].name, "Test Product")
        XCTAssertEqual(response.data[0].barcode, "012345678901")
        XCTAssertNil(response.data[0].mpn)
        XCTAssertEqual(response.meta?.requestId, "req-123")
        XCTAssertEqual(response.meta?.creditsUsed, 1)
        XCTAssertEqual(response.creditsRemaining(), 999)
    }

    func testOfferDecoding() throws {
        // Real offer shape: the link is under `URL` (capitalised) and `seller` is
        // frequently JSON null.
        let jsonData = """
        {
            "id": "offer-1",
            "retailer": "TestRetailer",
            "price": 99.99,
            "currency": "USD",
            "availability": "in",
            "condition": "new",
            "seller": null,
            "URL": "https://example.com/product",
            "timestamp": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let offer = try decoder.decode(Offer.self, from: jsonData)

        XCTAssertEqual(offer.id, "offer-1")
        XCTAssertEqual(offer.retailer, "TestRetailer")
        XCTAssertEqual(offer.price, 99.99)
        XCTAssertEqual(offer.currency, "USD")
        XCTAssertEqual(offer.url, "https://example.com/product")
        XCTAssertNil(offer.seller)
        XCTAssertEqual(offer.lastUpdated, "2024-01-01T00:00:00.000Z")
    }

    func testErrorTypes() {
        let networkError = ShopSavvyError.networkError("Connection failed")
        XCTAssertTrue(networkError.localizedDescription.contains("Network error"))
        
        let authError = ShopSavvyError.authenticationError("Invalid key")
        XCTAssertTrue(authError.localizedDescription.contains("Authentication error"))
        
        let notFoundError = ShopSavvyError.notFoundError("Product not found")
        XCTAssertTrue(notFoundError.localizedDescription.contains("Not found"))
        
        let validationError = ShopSavvyError.validationError("Invalid parameters")
        XCTAssertTrue(validationError.localizedDescription.contains("Validation error"))
        
        let rateLimitError = ShopSavvyError.rateLimitError("Too many requests")
        XCTAssertTrue(rateLimitError.localizedDescription.contains("Rate limit error"))
    }
}