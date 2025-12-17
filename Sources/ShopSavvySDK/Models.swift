import Foundation

// MARK: - API Meta

/// API response metadata containing credit usage info
public struct ApiMeta: Codable {
    public let creditsUsed: Int
    public let creditsRemaining: Int
    public let rateLimitRemaining: Int?

    enum CodingKeys: String, CodingKey {
        case creditsUsed = "credits_used"
        case creditsRemaining = "credits_remaining"
        case rateLimitRemaining = "rate_limit_remaining"
    }

    public init(creditsUsed: Int, creditsRemaining: Int, rateLimitRemaining: Int? = nil) {
        self.creditsUsed = creditsUsed
        self.creditsRemaining = creditsRemaining
        self.rateLimitRemaining = rateLimitRemaining
    }
}

// MARK: - API Response

/// Generic API response wrapper
public struct ApiResponse<T: Codable>: Codable {
    public let success: Bool
    public let data: T
    public let message: String?
    public let meta: ApiMeta?

    public init(success: Bool, data: T, message: String? = nil, meta: ApiMeta? = nil) {
        self.success = success
        self.data = data
        self.message = message
        self.meta = meta
    }

    /// Get credits used from meta object
    public func creditsUsed() -> Int {
        return meta?.creditsUsed ?? 0
    }

    /// Get credits remaining from meta object
    public func creditsRemaining() -> Int {
        return meta?.creditsRemaining ?? 0
    }
}

// MARK: - Pagination

/// Pagination info for search results
public struct PaginationInfo: Codable {
    public let total: Int
    public let limit: Int
    public let offset: Int
    public let returned: Int

    public init(total: Int, limit: Int, offset: Int, returned: Int) {
        self.total = total
        self.limit = limit
        self.offset = offset
        self.returned = returned
    }
}

/// Product search result with pagination
public struct ProductSearchResult: Codable {
    public let success: Bool
    public let data: [ProductDetails]
    public let pagination: PaginationInfo?
    public let meta: ApiMeta?

    public init(success: Bool, data: [ProductDetails], pagination: PaginationInfo? = nil, meta: ApiMeta? = nil) {
        self.success = success
        self.data = data
        self.pagination = pagination
        self.meta = meta
    }

    /// Get credits used from meta object
    public func creditsUsed() -> Int {
        return meta?.creditsUsed ?? 0
    }

    /// Get credits remaining from meta object
    public func creditsRemaining() -> Int {
        return meta?.creditsRemaining ?? 0
    }
}

// MARK: - Product Models

/// Product details model
public struct ProductDetails: Codable {
    public let title: String
    public let shopsavvy: String
    public let brand: String?
    public let category: String?
    public let images: [String]?
    public let barcode: String?
    public let amazon: String?
    public let model: String?
    public let mpn: String?
    public let color: String?

    public init(title: String, shopsavvy: String, brand: String? = nil, category: String? = nil, images: [String]? = nil, barcode: String? = nil, amazon: String? = nil, model: String? = nil, mpn: String? = nil, color: String? = nil) {
        self.title = title
        self.shopsavvy = shopsavvy
        self.brand = brand
        self.category = category
        self.images = images
        self.barcode = barcode
        self.amazon = amazon
        self.model = model
        self.mpn = mpn
        self.color = color
    }

    // Backward-compatible aliases

    /// @deprecated Use title instead
    public var name: String { title }

    /// @deprecated Use shopsavvy instead
    public var productId: String { shopsavvy }

    /// @deprecated Use amazon instead
    public var asin: String? { amazon }

    /// @deprecated Use images?.first instead
    public var imageUrl: String? { images?.first }
}

/// Product with nested offers (returned by offers endpoint)
public struct ProductWithOffers: Codable {
    public let title: String
    public let shopsavvy: String
    public let brand: String?
    public let category: String?
    public let images: [String]?
    public let barcode: String?
    public let amazon: String?
    public let model: String?
    public let mpn: String?
    public let color: String?
    public let offers: [Offer]

    public init(title: String, shopsavvy: String, brand: String? = nil, category: String? = nil, images: [String]? = nil, barcode: String? = nil, amazon: String? = nil, model: String? = nil, mpn: String? = nil, color: String? = nil, offers: [Offer] = []) {
        self.title = title
        self.shopsavvy = shopsavvy
        self.brand = brand
        self.category = category
        self.images = images
        self.barcode = barcode
        self.amazon = amazon
        self.model = model
        self.mpn = mpn
        self.color = color
        self.offers = offers
    }
}

// MARK: - Offer Models

/// Historical price point
public struct PriceHistoryEntry: Codable {
    public let date: String
    public let price: Double
    public let availability: String

    public init(date: String, price: Double, availability: String) {
        self.date = date
        self.price = price
        self.availability = availability
    }
}

/// Product offer model
public struct Offer: Codable {
    public let id: String
    public let retailer: String?
    public let price: Double?
    public let currency: String?
    public let availability: String?
    public let condition: String?
    public let url: String?
    public let seller: String?
    public let timestamp: String?
    public let history: [PriceHistoryEntry]?

    enum CodingKeys: String, CodingKey {
        case id, retailer, price, currency, availability, condition, seller, timestamp, history
        case url = "URL"
    }

    public init(id: String, retailer: String? = nil, price: Double? = nil, currency: String? = nil, availability: String? = nil, condition: String? = nil, url: String? = nil, seller: String? = nil, timestamp: String? = nil, history: [PriceHistoryEntry]? = nil) {
        self.id = id
        self.retailer = retailer
        self.price = price
        self.currency = currency
        self.availability = availability
        self.condition = condition
        self.url = url
        self.seller = seller
        self.timestamp = timestamp
        self.history = history
    }

    // Backward-compatible aliases

    /// @deprecated Use id instead
    public var offerId: String { id }

    /// @deprecated Use url instead
    public var offerUrl: String? { url }

    /// @deprecated Use timestamp instead
    public var lastUpdated: String? { timestamp }
}

/// Offer with price history
public struct OfferWithHistory: Codable {
    public let id: String
    public let retailer: String?
    public let price: Double?
    public let currency: String?
    public let availability: String?
    public let condition: String?
    public let url: String?
    public let seller: String?
    public let timestamp: String?
    public let priceHistory: [PriceHistoryEntry]

    enum CodingKeys: String, CodingKey {
        case id, retailer, price, currency, availability, condition, seller, timestamp
        case url = "URL"
        case priceHistory = "price_history"
    }

    public init(id: String, retailer: String? = nil, price: Double? = nil, currency: String? = nil, availability: String? = nil, condition: String? = nil, url: String? = nil, seller: String? = nil, timestamp: String? = nil, priceHistory: [PriceHistoryEntry] = []) {
        self.id = id
        self.retailer = retailer
        self.price = price
        self.currency = currency
        self.availability = availability
        self.condition = condition
        self.url = url
        self.seller = seller
        self.timestamp = timestamp
        self.priceHistory = priceHistory
    }
}

// MARK: - Monitoring Models

/// Request model for scheduling product monitoring
public struct ScheduleRequest: Codable {
    public let identifier: String
    public let frequency: String
    public let retailer: String?

    public init(identifier: String, frequency: String, retailer: String? = nil) {
        self.identifier = identifier
        self.frequency = frequency
        self.retailer = retailer
    }
}

/// Response model for scheduling operations
public struct ScheduleResponse: Codable {
    public let scheduled: Bool
    public let productId: String

    enum CodingKeys: String, CodingKey {
        case scheduled
        case productId = "product_id"
    }

    public init(scheduled: Bool, productId: String) {
        self.scheduled = scheduled
        self.productId = productId
    }
}

/// Response from batch scheduling
public struct ScheduleBatchResponse: Codable {
    public let identifier: String
    public let scheduled: Bool
    public let productId: String

    enum CodingKeys: String, CodingKey {
        case identifier, scheduled
        case productId = "product_id"
    }

    public init(identifier: String, scheduled: Bool, productId: String) {
        self.identifier = identifier
        self.scheduled = scheduled
        self.productId = productId
    }
}

/// Scheduled product model
public struct ScheduledProduct: Codable {
    public let productId: String
    public let identifier: String
    public let frequency: String
    public let retailer: String?
    public let createdAt: String
    public let lastRefreshed: String?

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case identifier, frequency, retailer
        case createdAt = "created_at"
        case lastRefreshed = "last_refreshed"
    }

    public init(productId: String, identifier: String, frequency: String, retailer: String? = nil, createdAt: String, lastRefreshed: String? = nil) {
        self.productId = productId
        self.identifier = identifier
        self.frequency = frequency
        self.retailer = retailer
        self.createdAt = createdAt
        self.lastRefreshed = lastRefreshed
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
    public let removed: Bool

    public init(removed: Bool) {
        self.removed = removed
    }
}

/// Response from batch removal
public struct RemoveBatchResponse: Codable {
    public let identifier: String
    public let removed: Bool

    public init(identifier: String, removed: Bool) {
        self.identifier = identifier
        self.removed = removed
    }
}

// MARK: - Usage Models

/// Current billing period details
public struct UsagePeriod: Codable {
    public let startDate: String
    public let endDate: String
    public let creditsUsed: Int
    public let creditsLimit: Int
    public let creditsRemaining: Int
    public let requestsMade: Int

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
        case creditsUsed = "credits_used"
        case creditsLimit = "credits_limit"
        case creditsRemaining = "credits_remaining"
        case requestsMade = "requests_made"
    }

    public init(startDate: String, endDate: String, creditsUsed: Int, creditsLimit: Int, creditsRemaining: Int, requestsMade: Int) {
        self.startDate = startDate
        self.endDate = endDate
        self.creditsUsed = creditsUsed
        self.creditsLimit = creditsLimit
        self.creditsRemaining = creditsRemaining
        self.requestsMade = requestsMade
    }
}

/// API usage information model
public struct UsageInfo: Codable {
    public let currentPeriod: UsagePeriod
    public let usagePercentage: Double

    enum CodingKeys: String, CodingKey {
        case currentPeriod = "current_period"
        case usagePercentage = "usage_percentage"
    }

    public init(currentPeriod: UsagePeriod, usagePercentage: Double) {
        self.currentPeriod = currentPeriod
        self.usagePercentage = usagePercentage
    }

    // Backward-compatible aliases

    /// @deprecated Use currentPeriod.creditsUsed instead
    public func getCreditsUsed() -> Int { currentPeriod.creditsUsed }

    /// @deprecated Use currentPeriod.creditsRemaining instead
    public func getCreditsRemaining() -> Int { currentPeriod.creditsRemaining }

    /// @deprecated Use currentPeriod.creditsLimit instead
    public func getCreditsTotal() -> Int { currentPeriod.creditsLimit }

    /// @deprecated Use currentPeriod.startDate instead
    public func getBillingPeriodStart() -> String { currentPeriod.startDate }

    /// @deprecated Use currentPeriod.endDate instead
    public func getBillingPeriodEnd() -> String { currentPeriod.endDate }
}
