
Pod::Spec.new do |s|

  s.name         = "zjqzySDK"
  s.version      = "0.0.3"
  s.summary      = "zjqzySDK swift"
  s.description  = <<-DESC
                   Written in Swift.
                   zjqzy private.
                   DESC

  s.homepage     = "https://github.com/zjqzy/zjqzySDK"
  s.license      = "BSD"

  s.author             = { "zjqzy" => "zjqzy03080312@163.com" }
  s.source       = { :git => "https://github.com/zjqzy/zjqzySDK.git", :tag => "#{s.version}" }

  s.swift_version = '5'
  s.platform     = :ios, "9.0"
  s.requires_arc  = true
  s.static_framework = true

  s.source_files = [
    'ZJQ_SDK/ZJQ_Log/*.{h,m,swift}',
    'ZJQ_SDK/CNKI_Server/*.{h,m,swift}',
  ]

  s.resources = 'ZJQ_SDK/**/*.bundle'
  # s.resource = "ZJQ_SDK/CNKI_Server/cnki_server.bundle"

  # s.source_files = 'JKLocationMananger/Classes/**/*'
  # s.exclude_files = "Classes/Exclude"

  s.public_header_files = "ZJQ_SDK/**/*.h"

  s.libraries = "iconv", "xml2","z"

  
  s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
