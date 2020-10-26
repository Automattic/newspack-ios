source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '13.0'
plugin 'cocoapods-repo-update'
workspace 'Newspack.xcworkspace'

def shared_pods
  pod 'CocoaLumberjack', '3.5.3'
  pod 'CocoaLumberjack/Swift', '3.5.3'
end



## Newspack
##
target 'Newspack' do
    project 'Newspack/Newspack.xcodeproj'
    shared_pods

    pod 'KeychainAccess', '3.2.0'
    pod 'Alamofire', '4.8.0'
    pod 'AlamofireImage', '3.5.2'

    pod 'WordPressAuthenticator', '~> 1.28.0-beta.2'
    pod 'WordPressKit', '~> 4.19'
    pod 'WPMediaPicker', '~> 1.7.2'
    pod 'WordPressFlux', '1.0.0'
    pod 'WordPressUI', '~> 1.7.2'

    target 'NewspackTests' do
        inherit! :search_paths

        pod 'OHHTTPStubs/Swift', '8.0.0'
    end

end



## Newspack
##
target 'NewspackFramework' do
  project 'Newspack/Newspack.xcodeproj'

  shared_pods

end

# Post Install
#
post_install do |installer|
  # Remove min deploy target to clean up build warnings.
  # See: https://stackoverflow.com/a/64048124
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
