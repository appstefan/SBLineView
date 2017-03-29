Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '9.0'
  s.name         = "SBLineView"
  s.version      = "0.1.3"
  s.summary      = "Interactive minimalistic line chart view in Swift"
  s.requires_arc = true
  s.description  = <<-DESC
                  Creates line charts driven by datasource and delegate protocols. Fully IBDesignable for easy customization in interface builder.
                   DESC
  s.homepage     = "https://github.com/appstefan/SBLineView"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author    = "Stefan"
  s.source       = { :git => "https://github.com/appstefan/SBLineView.git", :tag => "#{s.version}" }
  s.social_media_url = "https://twitter.com/BrittonStefan"
  s.framework = "UIKit"
  s.source_files = "SBLineView/**/*.{swift}"
end
