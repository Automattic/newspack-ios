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

def gutenberg(options)
    options[:git] = 'http://github.com/wordpress-mobile/gutenberg-mobile/'
    pod 'Gutenberg', options
    pod 'RNTAztecView', options

    gutenberg_dependencies options
end

def gutenberg_dependencies(options)
    dependencies = [
        'React',
        'yoga',
        'Folly',
        'react-native-safe-area',
    ]
    tag_or_commit = options[:tag] || options[:commit]

    for pod_name in dependencies do
        pod pod_name, :podspec => "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{tag_or_commit}/react-native-gutenberg-bridge/third-party-podspecs/#{pod_name}.podspec.json"
    end
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
	pod 'WordPressFlux', '1.0.0'

    ## Gutenberg
    ##
    gutenberg :tag => 'v1.1.1'
    pod 'RNSVG', :git => 'https://github.com/wordpress-mobile/react-native-svg.git', :tag => '9.3.3-gb'
    pod 'react-native-keyboard-aware-scroll-view', :git => 'https://github.com/wordpress-mobile/react-native-keyboard-aware-scroll-view.git', :tag => 'gb-v0.8.7'


    target 'NewspackTests' do
        inherit! :search_paths
    end

end
