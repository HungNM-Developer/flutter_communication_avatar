#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_communication_avatar.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_communication_avatar'
  s.version          = '1.0.0'
  s.summary          = 'Native communication push notifications with user avatars on iOS and Android.'
  s.description      = <<-DESC
A production-ready Flutter plugin for native communication push notifications with user avatars on iOS (INSendMessageIntent) and Android (MessagingStyle).
                       DESC
  s.homepage         = 'https://github.com/hungnguyen/flutter_communication_avatar'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hùng Nguyễn' => 'hungnguyen@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_communication_avatar/Sources/flutter_communication_avatar/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'Intents', 'UserNotifications', 'UIKit'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'flutter_communication_avatar_privacy' => ['flutter_communication_avatar/Sources/flutter_communication_avatar/PrivacyInfo.xcprivacy']}
end
