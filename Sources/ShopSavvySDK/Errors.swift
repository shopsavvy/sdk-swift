import Foundation

/// Errors that can occur when using the ShopSavvy SDK
public enum ShopSavvyError: Error, LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case notFoundError(String)
    case validationError(String)
    case rateLimitError(String)
    case apiError(String)
    case decodingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .notFoundError(let message):
            return "Not found: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .rateLimitError(let message):
            return "Rate limit error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .networkError:
            return "A network connectivity issue occurred"
        case .authenticationError:
            return "Invalid API key or authentication failed"
        case .notFoundError:
            return "The requested resource was not found"
        case .validationError:
            return "The request parameters failed validation"
        case .rateLimitError:
            return "Too many requests sent in a given time period"
        case .apiError:
            return "The API returned an error response"
        case .decodingError:
            return "Failed to decode the API response"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .authenticationError:
            return "Verify your API key is correct and active"
        case .notFoundError:
            return "Check that the requested resource exists"
        case .validationError:
            return "Review your request parameters and try again"
        case .rateLimitError:
            return "Wait a moment before making another request"
        case .apiError:
            return "Check the API documentation or contact support"
        case .decodingError:
            return "This may be a temporary issue, try again later"
        }
    }
}