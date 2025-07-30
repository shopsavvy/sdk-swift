import Foundation

// MARK: - API Response

/// Generic API response wrapper
public struct ApiResponse<T: Codable>: Codable {
    public let data: T
    public let meta: Meta
    
    public init(data: T, meta: Meta) {
        self.data = data
        self.meta = meta
    }
}

/// API response metadata
public struct Meta: Codable {
    public let requestId: String?
    public let timestamp: String?
    public let cached: Bool?
    public let creditsUsed: Int?
    
    enum CodingKeys: String, CodingKey {
        case requestId
        case timestamp
        case cached
        case creditsUsed = "credits_used"
    }
    
    public init(requestId: String?, timestamp: String?, cached: Bool?, creditsUsed: Int?) {
        self.requestId = requestId
        self.timestamp = timestamp
        self.cached = cached
        self.creditsUsed = creditsUsed
    }
}

// MARK: - Product Models

/// Product details model
public struct ProductDetails: Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let brand: String?
    public let category: String?
    public let upc: String?
    public let asin: String?
    public let modelNumber: String?
    public let images: [String]?
    public let specifications: [String: Any]?
    public let createdAt: String?
    public let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, brand, category, upc, asin, images, specifications
        case modelNumber = "model_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)
        asin = try container.decodeIfPresent(String.self, forKey: .asin)
        modelNumber = try container.decodeIfPresent(String.self, forKey: .modelNumber)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Handle specifications as flexible JSON
        if let specificationsData = try container.decodeIfPresent(Data.self, forKey: .specifications) {
            specifications = try JSONSerialization.jsonObject(with: specificationsData) as? [String: Any]
        } else {
            specifications = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(upc, forKey: .upc)
        try container.encodeIfPresent(asin, forKey: .asin)
        try container.encodeIfPresent(modelNumber, forKey: .modelNumber)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        
        if let specifications = specifications {
            let data = try JSONSerialization.data(withJSONObject: specifications)
            try container.encode(data, forKey: .specifications)
        }
    }
}

/// Product offer model
public struct Offer: Codable {
    public let retailer: String
    public let price: Double?
    public let currency: String?
    public let availability: String?
    public let condition: String?
    public let shippingCost: Double?
    public let url: String?
    public let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case retailer, price, currency, availability, condition, url
        case shippingCost = "shipping_cost"
        case lastUpdated = "last_updated"
    }
    
    public init(retailer: String, price: Double?, currency: String?, availability: String?, condition: String?, shippingCost: Double?, url: String?, lastUpdated: String?) {
        self.retailer = retailer
        self.price = price
        self.currency = currency
        self.availability = availability
        self.condition = condition
        self.shippingCost = shippingCost
        self.url = url
        self.lastUpdated = lastUpdated
    }
}

/// Historical price point
public struct PricePoint: Codable {
    public let date: String
    public let price: Double?
    public let availability: String?
    
    public init(date: String, price: Double?, availability: String?) {
        self.date = date
        self.price = price
        self.availability = availability
    }
}

/// Offer with price history
public struct OfferWithHistory: Codable {
    public let retailer: String
    public let price: Double?
    public let currency: String?
    public let availability: String?
    public let condition: String?
    public let shippingCost: Double?
    public let url: String?
    public let lastUpdated: String?
    public let priceHistory: [PricePoint]?
    
    enum CodingKeys: String, CodingKey {
        case retailer, price, currency, availability, condition, url
        case shippingCost = "shipping_cost"
        case lastUpdated = "last_updated"
        case priceHistory = "price_history"
    }
    
    public init(retailer: String, price: Double?, currency: String?, availability: String?, condition: String?, shippingCost: Double?, url: String?, lastUpdated: String?, priceHistory: [PricePoint]?) {
        self.retailer = retailer
        self.price = price
        self.currency = currency
        self.availability = availability
        self.condition = condition
        self.shippingCost = shippingCost
        self.url = url
        self.lastUpdated = lastUpdated
        self.priceHistory = priceHistory
    }
}

// MARK: - Monitoring Models

/// Request model for scheduling product monitoring
public struct ScheduleRequest: Codable {
    public let identifier: String
    public let frequency: String
    public let retailer: String?
    
    public init(identifier: String, frequency: String, retailer: String?) {
        self.identifier = identifier
        self.frequency = frequency
        self.retailer = retailer
    }
}

/// Response model for scheduling operations
public struct ScheduleResponse: Codable {
    public let success: Bool
    public let message: String?
    public let identifier: String?
    public let frequency: String?
    
    public init(success: Bool, message: String?, identifier: String?, frequency: String?) {
        self.success = success
        self.message = message
        self.identifier = identifier
        self.frequency = frequency
    }
}

/// Scheduled product model
public struct ScheduledProduct: Codable {
    public let identifier: String
    public let frequency: String
    public let retailer: String?
    public let createdAt: String?
    public let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case identifier, frequency, retailer
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
    }
    
    public init(identifier: String, frequency: String, retailer: String?, createdAt: String?, lastUpdated: String?) {
        self.identifier = identifier
        self.frequency = frequency
        self.retailer = retailer
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

/// Request model for removing scheduled products
public struct RemoveRequest: Codable {
    public let identifier: String
    
    public init(identifier: String) {
        self.identifier = identifier
    }
}

/// Response model for removal operations
public struct RemoveResponse: Codable {
    public let success: Bool
    public let message: String?
    public let identifier: String?
    
    public init(success: Bool, message: String?, identifier: String?) {
        self.success = success
        self.message = message
        self.identifier = identifier
    }
}

// MARK: - Usage Models

/// API usage information model
public struct UsageInfo: Codable {
    public let creditsUsed: Int?
    public let creditsRemaining: Int?
    public let creditsLimit: Int?
    public let resetDate: String?
    public let currentPeriodStart: String?
    public let currentPeriodEnd: String?
    
    enum CodingKeys: String, CodingKey {
        case creditsUsed = "credits_used"
        case creditsRemaining = "credits_remaining"
        case creditsLimit = "credits_limit"
        case resetDate = "reset_date"
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
    }
    
    public init(creditsUsed: Int?, creditsRemaining: Int?, creditsLimit: Int?, resetDate: String?, currentPeriodStart: String?, currentPeriodEnd: String?) {
        self.creditsUsed = creditsUsed
        self.creditsRemaining = creditsRemaining
        self.creditsLimit = creditsLimit
        self.resetDate = resetDate
        self.currentPeriodStart = currentPeriodStart
        self.currentPeriodEnd = currentPeriodEnd
    }
}