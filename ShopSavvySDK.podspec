Pod::Spec.new do |spec|
  spec.name          = "ShopSavvySDK"
  spec.version       = "1.0.0"
  spec.summary       = "Official Swift SDK for ShopSavvy Data API"
  
  spec.description   = <<-DESC
                       Official Swift SDK for ShopSavvy Data API - Access product data, pricing, and price history across thousands of retailers and millions of products.
                       DESC

  spec.homepage      = "https://shopsavvy.com/data"
  spec.license       = { :type => "MIT", :file => "LICENSE" }
  spec.author        = { "ShopSavvy Team" => "business@shopsavvy.com" }

  spec.ios.deployment_target = "13.0"
  spec.swift_version = '5.5'

  spec.source        = { :git => "https://github.com/shopsavvy/sdk-swift.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/ShopSavvySDK/**/*.swift"
  
  spec.frameworks    = "Foundation"
  spec.requires_arc  = true
  spec.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.5',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end