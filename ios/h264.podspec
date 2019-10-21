#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'h264'
  s.version          = '0.1.0'
  s.summary          = 'Convert single h264/h265 frames to images.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '11.3'

  swift_versions = ['4.0', '4.2', '5.0', '5.1']
  swift_versions << Pod::Validator::DEFAULT_SWIFT_VERSION if Pod::Validator.const_defined? "DEFAULT_SWIFT_VERSION"
  s.swift_versions = swift_versions

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end

