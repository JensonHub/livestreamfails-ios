# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

inhibit_all_warnings!
target 'LiveStreamFails' do
  pod 'Alamofire'
  pod 'HandyJSON'
  pod 'SnapKit'
  pod 'ReachabilitySwift'
  pod 'SwiftSoup'
  pod 'ZFPlayer', '~> 3.0'
  pod 'ZFPlayer/ControlView', '~> 3.0'
  pod 'ZFPlayer/AVPlayer', '~> 3.0'
  pod 'Kingfisher'
  pod 'ESPullToRefresh'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '4.2'
    end
  end
end
