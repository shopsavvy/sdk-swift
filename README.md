# ShopSavvy Data API - Swift SDK

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/badge/Platform-iOS%2013.0+%20|%20macOS%2010.15+%20|%20tvOS%2013.0+%20|%20watchOS%206.0+-blue.svg)](https://developer.apple.com/support/required-device-capabilities/)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-shopsavvy.com-blue)](https://shopsavvy.com/data/documentation)

Official Swift SDK for the [ShopSavvy Data API](https://shopsavvy.com/data). Access comprehensive product data, real-time pricing, and historical price trends across **thousands of retailers** and **millions of products**.

## ⚡ 30-Second Quick Start

```swift
// Add to Package.swift or Xcode Package Dependencies:
// https://github.com/shopsavvy/sdk-swift.git

import ShopSavvySDK

let client = ShopSavvyClient(apiKey: "ss_live_your_api_key_here")

Task {
    let product = try await client.getProductDetails(identifier: "012345678901")
    let offers = try await client.getCurrentOffers(identifier: "012345678901")
    let bestOffer = offers.data.min { $0.price ?? 0 < $1.price ?? 0 }
    
    print("\(product.data.name) - Best price: $\(bestOffer?.price ?? 0) at \(bestOffer?.retailer ?? "")")
}
```

## 📊 Feature Comparison

| Feature | Free Tier | Pro | Enterprise |
|---------|-----------|-----|-----------| 
| **API Calls/Month** | 1,000 | 100,000 | Unlimited |
| **Product Details** | ✅ | ✅ | ✅ |
| **Real-time Pricing** | ✅ | ✅ | ✅ |
| **Price History** | 30 days | 1 year | 5+ years |
| **Bulk Operations** | 10/batch | 100/batch | 1000/batch |
| **Retailer Coverage** | 50+ | 500+ | 1000+ |
| **Rate Limiting** | 60/hour | 1000/hour | Custom |
| **Support** | Community | Email | Phone + Dedicated |

## 🚀 Installation & Setup

### Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.5+ / Xcode 13.0+

### Swift Package Manager

**Method 1: Xcode**
1. File → Add Package Dependencies
2. Enter: `https://github.com/shopsavvy/sdk-swift.git`
3. Select version and add to target

**Method 2: Package.swift**
```swift
dependencies: [
    .package(url: "https://github.com/shopsavvy/sdk-swift.git", from: "1.0.0")
]
```

### CocoaPods

```ruby
pod 'ShopSavvySDK', '~> 1.0.0'
```

### Get Your API Key

1. **Sign up**: Visit [shopsavvy.com/data](https://shopsavvy.com/data)
2. **Choose plan**: Select based on your usage needs  
3. **Get API key**: Copy from your dashboard
4. **Test**: Run the 30-second example above

## 📖 Complete API Reference

### Client Configuration

```swift
import ShopSavvySDK

// Basic configuration
let client = ShopSavvyClient(apiKey: "ss_live_your_api_key_here")

// Advanced configuration
let client = ShopSavvyClient(
    apiKey: "ss_live_your_api_key_here",
    baseURL: "https://api.shopsavvy.com/v1",  // Custom base URL
    timeoutInterval: 60.0,                    // Request timeout
    retryAttempts: 3,                         // Retry failed requests
    userAgent: "MyApp/1.0.0"                 // Custom user agent
)

// Environment variable configuration
let apiKey = ProcessInfo.processInfo.environment["SHOPSAVVY_API_KEY"] ?? ""
let client = ShopSavvyClient(apiKey: apiKey)
```

### Product Lookup

#### Single Product
```swift
import ShopSavvySDK

class ProductService {
    private let client = ShopSavvyClient(apiKey: "ss_live_your_api_key_here")
    
    func lookupProduct() async {
        do {
            // Look up by barcode, ASIN, URL, model number, or ShopSavvy ID
            let product = try await client.getProductDetails(identifier: "012345678901")
            let amazonProduct = try await client.getProductDetails(identifier: "B08N5WRWNW")
            let urlProduct = try await client.getProductDetails(identifier: "https://www.amazon.com/dp/B08N5WRWNW")
            let modelProduct = try await client.getProductDetails(identifier: "MQ023LL/A") // iPhone model number
            
            print("📦 Product: \(product.data.name)")
            print("🏷️ Brand: \(product.data.brand ?? "N/A")")
            print("📂 Category: \(product.data.category ?? "N/A")")
            print("🔢 Product ID: \(product.data.id)")
            
            if let asin = product.data.asin {
                print("📦 ASIN: \(asin)")
            }
            
            if let model = product.data.modelNumber {
                print("🔧 Model: \(model)")
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
}
```

#### Bulk Product Lookup
```swift
func lookupMultipleProducts() async {
    // Process up to 100 products at once (Pro plan)
    let identifiers = [
        "012345678901", "B08N5WRWNW", "045496590048",
        "https://www.bestbuy.com/site/product/123456",
        "MQ023LL/A", "SM-S911U"  // iPhone and Samsung model numbers
    ]
    
    do {
        let products = try await client.getProductDetailsBatch(identifiers: identifiers)
        
        for (index, product) in products.data.enumerated() {
            if let product = product {
                print("✓ Found: \(product.name) by \(product.brand ?? "Unknown")")
            } else {
                print("❌ Failed to find product: \(identifiers[index])")
            }
        }
    } catch {
        print("Batch lookup error: \(error)")
    }
}
```

### Real-Time Pricing

#### iOS SwiftUI Price Comparison View
```swift
import SwiftUI
import ShopSavvySDK

struct PriceComparisonView: View {
    @State private var offers: [Offer] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let client = ShopSavvyClient(apiKey: "ss_live_your_api_key_here")
    private let productIdentifier = "012345678901"
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading offers...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    List(offers, id: \.retailer) { offer in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(offer.retailer)
                                    .font(.headline)
                                Text(offer.availability ?? "Unknown")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("$\(offer.price ?? 0, specifier: "%.2f")")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(offer == bestOffer ? .green : .primary)
                                
                                if offer == bestOffer {
                                    Text("BEST PRICE")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Price Comparison")
            .task {
                await loadOffers()
            }
            .refreshable {
                await loadOffers()
            }
        }
    }
    
    private var bestOffer: Offer? {
        offers.min { ($0.price ?? Double.max) < ($1.price ?? Double.max) }
    }
    
    private func loadOffers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.getCurrentOffers(identifier: productIdentifier)
            
            await MainActor.run {
                self.offers = response.data.sorted { ($0.price ?? 0) < ($1.price ?? 0) }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
```

#### Advanced Price Analysis
```swift
func analyzeOffers() async {
    do {
        let response = try await client.getCurrentOffers(identifier: "012345678901")
        let offers = response.data
        
        print("Found \(offers.count) offers across retailers")
        
        // Sort by price
        let sortedOffers = offers.sorted { ($0.price ?? 0) < ($1.price ?? 0) }
        
        guard let cheapest = sortedOffers.first,
              let mostExpensive = sortedOffers.last else { return }
        
        let total = offers.compactMap { $0.price }.reduce(0, +)
        let average = total / Double(offers.count)
        
        print("💰 Best price: \(cheapest.retailer) - $\(cheapest.price ?? 0)")
        print("💸 Highest price: \(mostExpensive.retailer) - $\(mostExpensive.price ?? 0)")
        print("📊 Average price: $\(String(format: "%.2f", average))")
        print("💡 Potential savings: $\(String(format: "%.2f", (mostExpensive.price ?? 0) - (cheapest.price ?? 0)))")
        
        // Filter by availability and condition
        let inStockOffers = offers.filter { $0.availability == "in_stock" }
        let newConditionOffers = offers.filter { $0.condition == "new" }
        
        print("✅ In-stock offers: \(inStockOffers.count)")
        print("🆕 New condition: \(newConditionOffers.count)")
        
    } catch {
        print("Error analyzing offers: \(error)")
    }
}
```

## 🚀 Production Deployment

### iOS App with MVVM Architecture

```swift
import SwiftUI
import ShopSavvySDK

// MARK: - View Model
@MainActor
class PriceTrackingViewModel: ObservableObject {
    @Published var products: [TrackedProduct] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = ShopSavvyClient(apiKey: "ss_live_your_api_key_here")
    
    func addProduct(identifier: String, targetPrice: Double) async {
        isLoading = true
        
        do {
            // Get product details
            let productResponse = try await client.getProductDetails(identifier: identifier)
            
            // Get current offers
            let offersResponse = try await client.getCurrentOffers(identifier: identifier)
            let bestOffer = offersResponse.data.min { ($0.price ?? 0) < ($1.price ?? 0) }
            
            // Schedule monitoring
            _ = try await client.scheduleProductMonitoring(identifier: identifier, frequency: "daily")
            
            let trackedProduct = TrackedProduct(
                identifier: identifier,
                name: productResponse.data.name,
                currentPrice: bestOffer?.price ?? 0,
                targetPrice: targetPrice,
                retailer: bestOffer?.retailer ?? "Unknown"
            )
            
            products.append(trackedProduct)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshPrices() async {
        for index in products.indices {
            do {
                let offers = try await client.getCurrentOffers(identifier: products[index].identifier)
                if let bestOffer = offers.data.min(by: { ($0.price ?? 0) < ($1.price ?? 0) }) {
                    products[index].currentPrice = bestOffer.price ?? 0
                    products[index].retailer = bestOffer.retailer
                    
                    // Check if target price reached
                    if let price = bestOffer.price, price <= products[index].targetPrice {
                        sendPriceAlert(for: products[index])
                    }
                }
            } catch {
                print("Error refreshing price for \(products[index].name): \(error)")
            }
        }
    }
    
    private func sendPriceAlert(for product: TrackedProduct) {
        // Send local notification
        let content = UNMutableNotificationContent()
        content.title = "Price Alert!"
        content.body = "\(product.name) is now $\(product.currentPrice) at \(product.retailer)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Model
struct TrackedProduct: Identifiable {
    let id = UUID()
    let identifier: String
    let name: String
    var currentPrice: Double
    let targetPrice: Double
    var retailer: String
}

// MARK: - View
struct PriceTrackingView: View {
    @StateObject private var viewModel = PriceTrackingViewModel()
    @State private var showingAddProduct = false
    
    var body: some View {
        NavigationView {
            List(viewModel.products) { product in
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.headline)
                    
                    HStack {
                        Text("Current: $\(product.currentPrice, specifier: "%.2f")")
                        Spacer()
                        Text("Target: $\(product.targetPrice, specifier: "%.2f")")
                    }
                    .font(.subheadline)
                    
                    Text("Best at: \(product.retailer)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Price Tracking")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddProduct = true
                    }
                }
            }
            .refreshable {
                await viewModel.refreshPrices()
            }
        }
        .sheet(isPresented: $showingAddProduct) {
            AddProductView(viewModel: viewModel)
        }
    }
}
```

### Background Price Monitoring

```swift
import BackgroundTasks
import ShopSavvySDK

class BackgroundPriceMonitor {
    static let shared = BackgroundPriceMonitor()
    private let client = ShopSavvyClient(apiKey: "ss_live_your_api_key_here")
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.myapp.price-refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func handleBackgroundRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await checkPrices()
            task.setTaskCompleted(success: true)
            scheduleBackgroundRefresh()
        }
    }
    
    private func checkPrices() async {
        // Get tracked products from UserDefaults or Core Data
        let trackedProducts = getTrackedProducts()
        
        for product in trackedProducts {
            do {
                let offers = try await client.getCurrentOffers(identifier: product.identifier)
                
                if let bestOffer = offers.data.min(by: { ($0.price ?? 0) < ($1.price ?? 0) }),
                   let price = bestOffer.price,
                   price <= product.targetPrice {
                    
                    // Send push notification
                    await sendPriceAlert(product: product, price: price, retailer: bestOffer.retailer)
                }
            } catch {
                print("Background price check failed for \(product.identifier): \(error)")
            }
        }
    }
    
    private func sendPriceAlert(product: TrackedProduct, price: Double, retailer: String) async {
        // Implementation for sending notifications
    }
    
    private func getTrackedProducts() -> [TrackedProduct] {
        // Implementation to retrieve tracked products
        return []
    }
}
```

## 🛠️ Development & Testing

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/shopsavvy/sdk-swift.git
cd sdk-swift

# Open in Xcode
open Package.swift

# Or build from command line
swift build

# Run tests
swift test
```

### Testing Your Integration

```swift
import ShopSavvySDK

class SDKTester {
    private let client = ShopSavvyClient(apiKey: "ss_test_your_test_key_here")
    
    func runTests() async {
        do {
            // Test product lookup
            let product = try await client.getProductDetails(identifier: "012345678901")
            print("✅ Product lookup: \(product.data.name)")
            
            // Test current offers
            let offers = try await client.getCurrentOffers(identifier: "012345678901")
            print("✅ Current offers: \(offers.data.count) found")
            
            // Test usage info
            let usage = try await client.getUsage()
            print("✅ API usage: \(usage.data.creditsRemaining ?? 0) credits remaining")
            
            print("\n🎉 All tests passed! SDK is working correctly.")
            
        } catch {
            print("❌ Test failed: \(error)")
        }
    }
}
```

## 📚 Additional Resources

- **[ShopSavvy Data API Documentation](https://shopsavvy.com/data/documentation)** - Complete API reference
- **[API Dashboard](https://shopsavvy.com/data/dashboard)** - Manage your API keys and usage
- **[GitHub Repository](https://github.com/shopsavvy/sdk-swift)** - Source code and issues
- **[Swift Package Index](https://swiftpackageindex.com/shopsavvy/sdk-swift)** - Package documentation
- **[Support](mailto:business@shopsavvy.com)** - Get help from our team

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Reporting bugs
- Suggesting enhancements  
- Submitting pull requests
- Development workflow
- Code standards

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 About ShopSavvy

**ShopSavvy** is the world's first mobile shopping app, helping consumers find the best deals since 2008. With over **40 million downloads** and millions of active users, ShopSavvy has saved consumers billions of dollars.

### Our Data API Powers:
- 🛒 **E-commerce platforms** with competitive intelligence  
- 📊 **Market research** with real-time pricing data
- 🏪 **Retailers** with inventory and pricing optimization
- 📱 **Mobile apps** with product lookup and price comparison
- 🤖 **Business intelligence** with automated price monitoring

### Why Choose ShopSavvy Data API?
- ✅ **Trusted by millions** - Proven at scale since 2008
- ✅ **Comprehensive coverage** - 1000+ retailers, millions of products  
- ✅ **Real-time accuracy** - Fresh data updated continuously
- ✅ **Developer-friendly** - Easy integration, great documentation
- ✅ **Reliable infrastructure** - 99.9% uptime, enterprise-grade
- ✅ **Flexible pricing** - Plans for every use case and budget

---

**Ready to get started?** [Sign up for your API key](https://shopsavvy.com/data) • **Need help?** [Contact us](mailto:business@shopsavvy.com)