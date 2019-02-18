source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'
plugin 'cocoapods-repo-update'
workspace 'Newspack.xcworkspace'

def shared_with_networking_pods
    pod 'AFNetworking', '3.2.1'
    pod 'Alamofire', '4.7.3'
end


## Newspack
##
target 'Newspack' do
    project 'Newspack/Newspack.xcodeproj'
    shared_with_networking_pods

    pod 'CocoaLumberjack', '3.4.2'
    pod 'WordPressAuthenticator', '~> 1.1.8'
	pod 'WordPressKit', '~> 1.8.0'
end
