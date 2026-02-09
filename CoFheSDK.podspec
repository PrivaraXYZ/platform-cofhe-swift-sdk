Pod::Spec.new do |s|
  s.name             = 'CoFheSDK'
  s.version          = '0.1.0'
  s.summary          = 'Swift SDK for Privara CoFHE — Fully Homomorphic Encryption service'
  s.description      = <<-DESC
    Type-safe Swift client for CoFHE (Confidential FHE) encryption service
    powered by Fhenix CoFHE. Supports all FHE types, batch encryption,
    health checks, and RFC 7807 error handling.
  DESC
  s.homepage         = 'https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'PrivaraXYZ' => 'dev@privara.xyz' }
  s.source           = { :git => 'https://github.com/PrivaraXYZ/platform-cofhe-swift-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.tvos.deployment_target = '15.0'
  s.watchos.deployment_target = '8.0'

  s.swift_version = '5.9'
  s.source_files = 'Sources/CoFheSDK/**/*.swift'
end
