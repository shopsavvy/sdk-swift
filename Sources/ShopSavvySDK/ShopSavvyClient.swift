import Foundation

/// Official Swift client for ShopSavvy Data API
///
/// Provides access to product data, pricing information, and price history
/// across thousands of retailers and millions of products.
///
/// Example usage:
/// ```swift
/// let client = ShopSavvyClient(apiKey: "ss_live_your_api_key_here")
/// 
/// do {
///     let productResponse = try await client.getProductDetails(identifier: "012345678901")
///     print("Product: \(productResponse.data.name)")
/// } catch {
///     print("Error: \(error)")
/// }
/// ```
@available(iOS 13.0, macOS 10.15, *)
public class ShopSavvyClient {
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    /// Create a new ShopSavvy Data API client
    /// - Parameter apiKey: Your ShopSavvy API key
    public init(apiKey: String) {
        self.init(apiKey: apiKey, baseURL: "https://api.shopsavvy.com/v1", timeoutInterval: 30.0)
    }
    
    /// Create a new ShopSavvy Data API client with custom configuration
    /// - Parameters:
    ///   - apiKey: Your ShopSavvy API key
    ///   - baseURL: Base URL for the API
    ///   - timeoutInterval: Request timeout interval in seconds
    public init(apiKey: String, baseURL: String, timeoutInterval: TimeInterval) {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("API key is required. Get one at https://shopsavvy.com/data")
        }
        
        guard apiKey.hasPrefix("ss_live_") || apiKey.hasPrefix("ss_test_") else {
            fatalError("Invalid API key format. API keys should start with ss_live_ or ss_test_")
        }
        
        self.apiKey = apiKey
        self.baseURL = baseURL
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = timeoutInterval
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        // Configure date decoding if needed
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - Product Details
    
    /// Look up product details by identifier
    /// - Parameters:
    ///   - identifier: Product identifier (barcode, ASIN, URL, model number, or ShopSavvy product ID)
    ///   - format: Response format ('json' or 'csv')
    /// - Returns: Product details
    public func getProductDetails(identifier: String, format: String? = nil) async throws -> ApiResponse<ProductDetails> {
        var components = URLComponents(string: "\(baseURL)/products/details")!
        components.queryItems = [
            URLQueryItem(name: "identifier", value: identifier)
        ]
        
        if let format = format {
            components.queryItems?.append(URLQueryItem(name: "format", value: format))
        }
        
        return try await performRequest(url: components.url!)
    }
    
    /// Look up details for multiple products
    /// - Parameters:
    ///   - identifiers: List of product identifiers
    ///   - format: Response format ('json' or 'csv')
    /// - Returns: List of product details
    public func getProductDetailsBatch(identifiers: [String], format: String? = nil) async throws -> ApiResponse<[ProductDetails]> {
        var components = URLComponents(string: "\(baseURL)/products/details")!
        components.queryItems = [
            URLQueryItem(name: "identifiers", value: identifiers.joined(separator: ","))
        ]
        
        if let format = format {
            components.queryItems?.append(URLQueryItem(name: "format", value: format))
        }
        
        return try await performRequest(url: components.url!)
    }
    
    // MARK: - Current Offers
    
    /// Get current offers for a product
    /// - Parameters:
    ///   - identifier: Product identifier
    ///   - retailer: Optional retailer to filter by
    ///   - format: Response format ('json' or 'csv')
    /// - Returns: Current offers
    public func getCurrentOffers(identifier: String, retailer: String? = nil, format: String? = nil) async throws -> ApiResponse<[Offer]> {
        var components = URLComponents(string: "\(baseURL)/products/offers")!
        components.queryItems = [
            URLQueryItem(name: "identifier", value: identifier)
        ]
        
        if let retailer = retailer {
            components.queryItems?.append(URLQueryItem(name: "retailer", value: retailer))
        }
        if let format = format {
            components.queryItems?.append(URLQueryItem(name: "format", value: format))
        }
        
        return try await performRequest(url: components.url!)
    }
    
    /// Get current offers for multiple products
    /// - Parameters:
    ///   - identifiers: List of product identifiers
    ///   - retailer: Optional retailer to filter by
    ///   - format: Response format ('json' or 'csv')
    /// - Returns: Map of identifiers to their offers
    public func getCurrentOffersBatch(identifiers: [String], retailer: String? = nil, format: String? = nil) async throws -> ApiResponse<[String: [Offer]]> {
        var components = URLComponents(string: "\(baseURL)/products/offers")!
        components.queryItems = [
            URLQueryItem(name: "identifiers", value: identifiers.joined(separator: ","))
        ]
        
        if let retailer = retailer {
            components.queryItems?.append(URLQueryItem(name: "retailer", value: retailer))
        }
        if let format = format {
            components.queryItems?.append(URLQueryItem(name: "format", value: format))
        }
        
        return try await performRequest(url: components.url!)
    }
    
    // MARK: - Price History
    
    /// Get price history for a product
    /// - Parameters:
    ///   - identifier: Product identifier
    ///   - startDate: Start date (YYYY-MM-DD format)
    ///   - endDate: End date (YYYY-MM-DD format)
    ///   - retailer: Optional retailer to filter by
    ///   - format: Response format ('json' or 'csv')
    /// - Returns: Offers with price history
    public func getPriceHistory(identifier: String, startDate: String, endDate: String, retailer: String? = nil, format: String? = nil) async throws -> ApiResponse<[OfferWithHistory]> {
        var components = URLComponents(string: "\(baseURL)/products/history")!
        components.queryItems = [
            URLQueryItem(name: "identifier", value: identifier),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate)
        ]
        
        if let retailer = retailer {
            components.queryItems?.append(URLQueryItem(name: "retailer", value: retailer))
        }
        if let format = format {
            components.queryItems?.append(URLQueryItem(name: "format", value: format))
        }
        
        return try await performRequest(url: components.url!)
    }
    
    // MARK: - Monitoring
    
    /// Schedule product monitoring
    /// - Parameters:
    ///   - identifier: Product identifier
    ///   - frequency: How often to refresh ('hourly', 'daily', 'weekly')
    ///   - retailer: Optional retailer to monitor
    /// - Returns: Scheduling confirmation
    public func scheduleProductMonitoring(identifier: String, frequency: String, retailer: String? = nil) async throws -> ApiResponse<ScheduleResponse> {
        let url = URL(string: "\(baseURL)/products/schedule")!
        let request = ScheduleRequest(identifier: identifier, frequency: frequency, retailer: retailer)
        
        return try await performRequest(url: url, method: "POST", body: request)
    }
    
    /// Get all scheduled products
    /// - Returns: List of scheduled products
    public func getScheduledProducts() async throws -> ApiResponse<[ScheduledProduct]> {
        let url = URL(string: "\(baseURL)/products/scheduled")!
        return try await performRequest(url: url)
    }
    
    /// Remove product from monitoring schedule
    /// - Parameter identifier: Product identifier to remove
    /// - Returns: Removal confirmation
    public func removeProductFromSchedule(identifier: String) async throws -> ApiResponse<RemoveResponse> {
        let url = URL(string: "\(baseURL)/products/schedule")!
        let request = RemoveRequest(identifier: identifier)
        
        return try await performRequest(url: url, method: "DELETE", body: request)
    }
    
    // MARK: - Usage
    
    /// Get API usage information
    /// - Returns: Current usage and credit information
    public func getUsage() async throws -> ApiResponse<UsageInfo> {
        let url = URL(string: "\(baseURL)/usage")!
        return try await performRequest(url: url)
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Codable>(url: URL, method: String = "GET", body: Codable? = nil) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ShopSavvy-Swift-SDK/1.0.0", forHTTPHeaderField: "User-Agent")
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShopSavvyError.networkError("Invalid response type")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = errorMessage?["error"] as? String ?? "Unknown error"
            
            switch httpResponse.statusCode {
            case 401:
                throw ShopSavvyError.authenticationError("Authentication failed. Check your API key.")
            case 404:
                throw ShopSavvyError.notFoundError("Resource not found")
            case 422:
                throw ShopSavvyError.validationError("Request validation failed. Check your parameters.")
            case 429:
                throw ShopSavvyError.rateLimitError("Rate limit exceeded. Please slow down your requests.")
            default:
                throw ShopSavvyError.apiError("HTTP \(httpResponse.statusCode): \(message)")
            }
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ShopSavvyError.decodingError("Failed to decode response: \(error.localizedDescription)")
        }
    }
}