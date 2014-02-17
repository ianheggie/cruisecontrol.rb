source "http://rubygems.org"

gem "rails", "3.2.16"
gem "tzinfo"
gem "rack"
gem "bundler"

gem "httparty"
gem "api_cache"
gem "xml-simple"
gem "rake"
gem "jquery-rails"
gem "abstract"
gem "xmpp4r"
gem "puma", '< 2.7.0'  # 2.7.[01] breaks compatibility with ruby 1.8.7

group :development do
  gem "rcov", '0.9.9', :platforms => [:ruby_18]
  gem "mocha", :require => false
  gem "rack-test", :require => "rack/test"
end

platform :jruby do
  gem 'jruby-openssl'
end

gem "googlecharts"

group :development do
  gem 'powder'
end

group :test do
  gem 'debugger', :platforms => :mri_19 unless ENV['TRAVIS'] == 'true'
end

gem 'system_timer', :platforms => :ruby_18
