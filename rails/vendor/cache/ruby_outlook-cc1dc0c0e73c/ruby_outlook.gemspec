# -*- encoding: utf-8 -*-
# stub: ruby_outlook 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby_outlook".freeze
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jason Johnston".freeze]
  s.bindir = "exe".freeze
  s.date = "2018-12-07"
  s.description = "This ruby gem provides functions for common operations with the Outlook Mail, Calendar, and Contacts APIs.".freeze
  s.email = ["jasonjoh@microsoft.com".freeze]
  s.files = [".gitattributes".freeze, ".gitignore".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.TXT".freeze, "README.md".freeze, "Rakefile".freeze, "bin/console".freeze, "bin/setup".freeze, "lib/ruby_outlook.rb".freeze, "lib/ruby_outlook/version.rb".freeze, "lib/run-tests.rb".freeze, "ruby_outlook.gemspec".freeze]
  s.homepage = "https://github.com/jasonjoh/ruby_outlook".freeze
  s.rubygems_version = "2.7.8".freeze
  s.summary = "A ruby gem to invoke the Outlook REST APIs.".freeze

  s.installed_by_version = "2.7.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<faraday>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<uuidtools>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.8"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    else
      s.add_dependency(%q<faraday>.freeze, [">= 0"])
      s.add_dependency(%q<uuidtools>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.8"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    end
  else
    s.add_dependency(%q<faraday>.freeze, [">= 0"])
    s.add_dependency(%q<uuidtools>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.8"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
  end
end
