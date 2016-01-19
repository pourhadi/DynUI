#
# Be sure to run `pod lib lint DynUI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DynUI"
  s.version          = "0.1.1"
  s.summary          = "A short description of DynUI."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       DESC

  s.homepage         = "https://github.com/pourhadi/DynUI"
  s.license          = 'MIT'
  s.author           = { "Daniel Pourhadi" => "dan@pourhadi.com" }
  s.source           = { :git => "https://github.com/pourhadi/DynUI.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'DynUI' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit'
s.dependency 'SuperSerial', :git => "https://github.com/pourhadi/SuperSerial.git"
end
