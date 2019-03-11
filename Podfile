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

def gutenberg_pod(name, branch=nil)
    gutenberg_branch=branch || 'master'
    pod name, :podspec => "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{gutenberg_branch}/react-native-gutenberg-bridge/third-party-podspecs/#{name}.podspec.json"
end

def gutenberg(options)
    pod 'Gutenberg', options
    pod 'RNTAztecView', options
end

## Newspack
##
target 'Newspack' do
    project 'Newspack/Newspack.xcodeproj'
    shared_with_networking_pods

    pod 'CocoaLumberjack', '3.4.2'
	pod 'KeychainAccess', '3.1.2'
    pod 'WordPressAuthenticator', '~> 1.1.8'
    pod 'WordPressKit', '~> 1.8.0'
    pod 'WPMediaPicker', '1.3.2'

    ## Gutenberg
    ##
    gutenberg :git => 'http://github.com/wordpress-mobile/gutenberg-mobile/', :tag => 'v1.0.1'
    gutenberg_pod 'React'
    gutenberg_pod 'yoga'
    gutenberg_pod 'Folly'
    gutenberg_pod 'react-native-safe-area'
    pod 'RNSVG', :git => 'https://github.com/wordpress-mobile/react-native-svg.git', :tag => '8.0.9-gb.0'
    pod 'react-native-keyboard-aware-scroll-view', :git => 'https://github.com/wordpress-mobile/react-native-keyboard-aware-scroll-view.git', :tag => 'gb-v0.8.5'

end
