#
# Be sure to run `pod lib lint DynUI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name             = 'DynUI'
  spec.version          = '0.1.3'
  spec.license          = { :type => 'MIT' }
  spec.homepage         = 'https://github.com/pourhadi/DynUI'
  spec.authors          = { 'Dan Pourhadi' => 'dan@pourhadi.com' }
  spec.summary          = 'Style library for iOS.'
  spec.source           = { :git => "https://github.com/pourhadi/DynUI.git", :tag => spec.version.to_s }
  spec.source_files = 'Pod/Classes/**/*'
  spec.framework        = 'SystemConfiguration'
  spec.requires_arc     = true
  spec.dependency 'SuperSerial'
  spec.dependency 'RxSwift',    '~> 2.0'
  spec.dependency 'RxCocoa',    '~> 2.0'
  spec.dependency 'RxBlocking', '~> 2.0'
end
