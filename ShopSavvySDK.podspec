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
  spec.source_files  = "Sources/ShopSavvySDK/**/*.{h,swift}"
  spec.public_header_files = "Sources/ShopSavvySDK/**/*.h"
  spec.module_map    = "Sources/ShopSavvySDK/module.modulemap"
  
  spec.frameworks    = "Foundation"
  spec.requires_arc  = true
end