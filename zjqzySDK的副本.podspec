
Pod::Spec.new do |s|

  s.name         = "zjqzySDK"
  s.version      = "0.0.1"
  s.summary      = "zjqzySDK swift"


  s.homepage     = "https://github.com/zjqzy/zjqzySDK"
  s.license      = "MIT"



  s.author             = { "zjqzy" => "zjqzy03080312@163.com" }

  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/zjqzy/zjqzySDK.git", :tag => "#{s.version}" }

  s.swift_version = '5'

# s.source_files = [
#    'Source/*.{h,swift}',
#    'Source/**/*.swift',
#    'Vendor/**/*.swift',
#  ]

  # s.source_files = 'JKLocationMananger/Classes/**/*'
  # s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"

  s.subspec 'ZJQ_SDK' do |base|

    # 在这个属性中声明过的.h文件能够使用<>方法联想调用（可选属性）
    base.public_header_files = 'ZJQ_SDK/**/*'

    base.subspec 'ZJQ_Log' do |log|
      log.source_files = 'ZJQ_SDK/ZJQ_Log/**/*'
    end

    base.subspec 'CNKI_Server' do |server|
      server.dependency 'zjqzySDK/ZJQ_SDK/ZJQ_Log'
      server.source_files = 'ZJQ_SDK/CNKI_Server/**/*'
    end

  end


  # s.framework  = "SomeFramework"
  s.frameworks = "UIKit", "Foundation"

  # s.library   = "iconv"
  s.libraries = "iconv", "xml2"

  s.requires_arc = true
  s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
