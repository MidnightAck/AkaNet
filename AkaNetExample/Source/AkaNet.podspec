#
# Be sure to run `pod lib lint BNShare.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AkaNet'
  s.version          = '0.0.1'
  s.summary          = 'AkaNet'
  s.description      = <<-DESC
  STDebug
                       DESC
  s.homepage         = 'https'
  s.author           = { 'sekitou' => 'wendaoliu40@gmail.com' }
  s.source           = {
    :git => 'ssh://no_such_git_yet/haha.git', :tag => s.version.to_s
  }
  s.ios.deployment_target = '14.0'
  
  s.source_files = '**/*.{h,m,swift}'
  
  s.frameworks = 'Foundation', 'UIKit'
  
  s.dependency 'HandyJSON'
  
end
