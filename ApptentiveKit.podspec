Pod::Spec.new do |spec|
  spec.name             = "ApptentiveKit"
  spec.version          = "7.4.0"
  spec.summary          = "Alchemer Digital iOS SDK (formerly Apptentive)."
  spec.homepage         = "https://www.apptentive.com/"
  spec.license          = "BSD"
  spec.swift_version    = "5.5"
  spec.author           = { 'Alchemer Digital SDK Team' => 'sdks@apptentive.com' }
  spec.platform         = :ios, "15.0"
  spec.source           = { :git => "https://github.com/apptentive/apptentive-kit-ios.git", :tag => "v#{spec.version}" }
  spec.source_files     = "Sources/ApptentiveKit/**/*.{h,swift}"
  spec.resource_bundles = { "ApptentiveKitResources" => [ "Sources/ApptentiveKit/Resources/*.lproj", "Sources/ApptentiveKit/Resources/Media.xcassets", "Sources/ApptentiveKit/Resources/Distribution.plist", "Sources/ApptentiveKit/Resources/PrivacyInfo.xcprivacy" ] }
  spec.frameworks       = "StoreKit", "UIKit", "Foundation", "OSLog"
end
