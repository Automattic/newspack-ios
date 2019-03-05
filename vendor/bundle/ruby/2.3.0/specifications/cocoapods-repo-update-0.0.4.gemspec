# -*- encoding: utf-8 -*-
# stub: cocoapods-repo-update 0.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "cocoapods-repo-update"
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["James Treanor"]
  s.date = "2019-01-02"
  s.description = "A CocoaPods plugin that updates your specs repos on pod install if needed."
  s.email = ["jtreanor3@gmail.com"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md"]
  s.homepage = "https://github.com/wordpress-mobile/cocoapods-repo-update"
  s.licenses = ["GPL-2.0"]
  s.rubygems_version = "2.5.1"
  s.summary = "cocoapods-repo-update is a CocoaPods plugin that checks your dependencies when you run `pod install` and updates the local specs repositories if needed."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cocoapods>, [">= 1.3.0", "~> 1.0"])
    else
      s.add_dependency(%q<cocoapods>, [">= 1.3.0", "~> 1.0"])
    end
  else
    s.add_dependency(%q<cocoapods>, [">= 1.3.0", "~> 1.0"])
  end
end
