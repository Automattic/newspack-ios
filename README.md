# Newspack for iOS

A companion app to the Newspack service.


## Getting started

1. Create a local clone of the repository.
2. `cd` into the workspace folder and run `rake dependencies`. This should configure the bundle and install any missing libraries and cocoapods.
3. Ensure you have a local copy of our secrets repo. Lacking that, create a JSON file containing the secrets at `~/.mobile-secrets/iOS/newspack/newspack-app-credentials.json`
4. Open `Newspack.xcworkspace` in Xcode.  You should be good to go. 

If you need to update installed pods due to changes in the `Podfile` run `bundle exec pod install` to ensure the correct versio of CocoaPods is used.
