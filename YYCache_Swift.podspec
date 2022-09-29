#
# Be sure to run `pod lib lint YYCache_Swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YYCache_Swift'
  s.version          = '1.0.0'
  s.summary          = 'use YYCache in Swift'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/syt2/YYCache_Swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'syt2' => 'dreamcontinue.cd@gmail.com' }
  s.source           = { :git => 'https://github.com/syt2/YYCache_Swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'
  s.requires_arc = true
  s.source_files = 'YYCache_Swift/Classes/**/*', "YYCache_Swift/Classes/*.{swift,h,m}"
#  s.public_header_files = 'YYCache_Swift/Classes/**/*.h', "YYCache_Swift/Classes/*.h"
  s.swift_version = '5.0'

  s.libraries = 'sqlite3'
  s.frameworks = 'UIKit', 'CoreFoundation', 'QuartzCore' 
  # s.resource_bundles = {
  #   'YYCache_Swift' => ['YYCache_Swift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
