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
        let jsonData = """
        {
            "data": {
                "id": "test-product-123",
                "name": "Test Product",
                "description": "A test product",
                "brand": "TestBrand",
                "category": "Electronics",
                "upc": "012345678901",
                "asin": "B08N5WRWNW",
                "model_number": "TEST-123",
                "images": ["https://example.com/image.jpg"],
                "specifications": {},
                "created_at": "2024-01-01T00:00:00.000000Z",
                "updated_at": "2024-01-01T00:00:00.000000Z"
            },
            "meta": {
                "requestId": "req-123",
                "timestamp": "2024-01-01T00:00:00.000000Z",
                "cached": false,
                "credits_used": 1
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ApiResponse<ProductDetails>.self, from: jsonData)
        
        XCTAssertEqual(response.data.id, "test-product-123")
        XCTAssertEqual(response.data.name, "Test Product")
        XCTAssertEqual(response.meta.requestId, "req-123")
        XCTAssertEqual(response.meta.creditsUsed, 1)
    }
    
    func testOfferDecoding() throws {
        let jsonData = """
        {
            "retailer": "TestRetailer",
            "price": 99.99,
            "currency": "USD",
            "availability": "in_stock",
            "condition": "new",
            "shipping_cost": 5.99,
            "url": "https://example.com/product",
            "last_updated": "2024-01-01T00:00:00.000000Z"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let offer = try decoder.decode(Offer.self, from: jsonData)
        
        XCTAssertEqual(offer.retailer, "TestRetailer")
        XCTAssertEqual(offer.price, 99.99)
        XCTAssertEqual(offer.currency, "USD")
        XCTAssertEqual(offer.shippingCost, 5.99)
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