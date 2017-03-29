Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '9.0'
  s.name         = "SBLineView"
  s.version      = "0.1.2"
  s.summary      = "A minimalist, designable line chart view in Swift"
  s.requires_arc = true
  s.description  = <<-DESC
                  Creates customizable interactive line charts using the common datasource and delegate protocol pattern.
                   DESC
  s.homepage     = "https://github.com/appstefan/SBLineView"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author    = "Stefan"
  s.source       = { :git => "https://github.com/appstefan/SBLineView.git", :tag => "#{s.version}" }
  s.social_media_url = "https://twitter.com/BrittonStefan"
  s.framework = "UIKit"
  s.source_files = "SBLineView/**/*.{swift}"
end
