#
# Be sure to run `pod lib lint OSPlayerRegister.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OSPlayerRegister'
  s.version          = '0.1.0'
  s.summary          = 'A OSPlayerRegister provice easy onesignal regisration for banned country.'
  s.description      = 'Register  OneSignal Player when OneSignal banned your country'

  s.homepage         = 'https://github.com/farshadmb/OSPlayerRegister'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'farshadmb' => 'info@ifarshad.me' }
  s.source           = { :git => 'https://github.com/farshadmb/OSPlayerRegister.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/xtremeagle'

  s.ios.deployment_target = '8.0'

  s.source_files = 'OSPlayerRegister/Classes/**/*'
  s.public_header_files = 'Pod/Classes/**/*.h'
#   s.frameworks = 'UIKit', 'MapKit'
   s.dependency  'AFNetworking', '~> 3.0'
end
