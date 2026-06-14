Pod::Spec.new do |s|
  s.name = 'AliyunNumberAuth'
  s.version = '2.14.17'
  s.summary = 'Aliyun number auth iOS SDK bridge for Narrate.'
  s.description = 'Wraps the Aliyun one-click login SDK and exposes it to Flutter through a MethodChannel.'
  s.homepage = 'https://www.aliyun.com/'
  s.license = { :type => 'Commercial', :text => 'Aliyun Number Authentication SDK' }
  s.author = { 'Narrate' => 'narrate' }
  s.source = { :path => '.' }
  s.ios.deployment_target = '12.0'

  s.source_files = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.vendored_frameworks = 'ATAuthSDK_D.xcframework'
  s.dependency 'Flutter'
  s.frameworks = 'UIKit', 'Foundation', 'QuartzCore'
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -framework "ATAuthSDK_D"'
  }
end
