#
# Be sure to run `pod lib lint YFProgressHud.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YFProgressHud'
  s.version          = '1.0.0'
  s.summary          = 'An iOS activity indicator view.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  YFProgressHud is a framework that rewrite the [MBProgressHUD](https://github.com/jdg/MBProgressHUD) in Swift.
                       DESC

  s.homepage         = 'https://github.com/yonfong/YFProgressHud'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yonfong' => 'yongfongzhang@163.com' }
  s.source           = { :git => 'https://github.com/yonfong/YFProgressHud.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '10.0'
  s.swift_version         = '5.0'

  s.source_files = 'YFProgressHud/Classes/**/*'
  
  s.dependency 'SnapKit', '~> 5.6.0'
  
end
