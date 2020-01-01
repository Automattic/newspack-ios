source 'https://rubygems.org' do
  gem 'rake'
  gem 'cocoapods', '~> 1.7.0'
  gem 'cocoapods-repo-update', '~> 0.0.3'
  gem 'fastlane', '2.133.0'
end

plugins_path = File.join(File.dirname(__FILE__), 'Scripts/fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)