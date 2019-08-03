source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

platform :ios, '11.0'
plugin 'cocoapods-repo-update'
workspace 'Newspack.xcworkspace'

def shared_with_networking_pods
    pod 'Alamofire', '4.7.3'
end

def gutenberg(options)
    options[:git] = 'http://github.com/wordpress-mobile/gutenberg-mobile/'
    local_gutenberg = ENV['LOCAL_GUTENBERG']
    if local_gutenberg
      options = { :path => local_gutenberg.include?('/') ? local_gutenberg : '../gutenberg-mobile' }
    end
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
        'react-native-video',
    ]
    if options[:path]
        podspec_prefix = options[:path]
    else
        tag_or_commit = options[:tag] || options[:commit]
        podspec_prefix = "https://raw.githubusercontent.com/wordpress-mobile/gutenberg-mobile/#{tag_or_commit}"
    end

    for pod_name in dependencies do
        pod pod_name, :podspec => "#{podspec_prefix}/react-native-gutenberg-bridge/third-party-podspecs/#{pod_name}.podspec.json"
    end
end


## Newspack
##
target 'Newspack' do
    project 'Newspack/Newspack.xcodeproj'
    shared_with_networking_pods

    pod 'CocoaLumberjack', '3.5.2'
    pod 'KeychainAccess', '3.2.0'

    pod 'WordPressAuthenticator', '~> 1.5.0'
    pod 'WordPressKit', '~> 4.1.1'
    pod 'WPMediaPicker', '~> 1.4.1'
    pod 'WordPressFlux', '1.0.0'
    pod 'WordPressUI', '~> 1.3.0'

    ## Gutenberg
    ##
    gutenberg :tag => 'v1.5.1'
    pod 'RNSVG', :git => 'https://github.com/wordpress-mobile/react-native-svg.git', :tag => '9.3.3-gb'
    pod 'react-native-keyboard-aware-scroll-view', :git => 'https://github.com/wordpress-mobile/react-native-keyboard-aware-scroll-view.git', :tag => 'gb-v0.8.7'

    target 'NewspackTests' do
        inherit! :search_paths

        pod 'OHHTTPStubs/Swift', '6.1.0'
    end

end

