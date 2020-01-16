source 'https://rubygems.org' do
  gem 'rake'
  gem 'cocoapods', '~> 1.8.0'
  gem 'cocoapods-repo-update', '~> 0.0.3'
  gem 'dotenv'
  gem 'fastlane', '2.140.0'
end

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
