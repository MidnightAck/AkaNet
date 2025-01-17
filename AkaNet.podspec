Pod::Spec.new do |spec|
  spec.name         = "AkaNet"
  spec.version      = "1.0.1"
  spec.summary      = "A networking library built on top of Moya with advanced features."
  spec.platform     = :ios, "15.0"
  spec.description  = <<-DESC
    AkaNet is a powerful networking library for iOS applications, built on top of Moya. It provides features like request prioritization, a caching pool, multiple caching strategies, streaming, and persistent connections.
  DESC

  spec.homepage     = "https://github.com/MidnightAck/AkaNet"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.authors      = ["sekitou"]
  spec.social_media_url = "https://x.com/MidnightAckX"
  spec.source       = { :git => "https://github.com/MidnightAck/AkaNet.git", :tag => "#{spec.version}" }
  spec.source_files = "Source/**/*.swift"

  # Project Dependencies
  spec.dependency 'Alamofire'
  spec.dependency 'Reachability'
  
  spec.frameworks = 'Foundation', 'UIKit'

  # Swift Version
  spec.swift_versions = ['5.0']

  # Project Settings
  spec.requires_arc = true

  # Additional Configuration
  # Uncomment and modify if specific xcconfig settings are needed
  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
end
