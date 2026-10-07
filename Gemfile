source "https://rubygems.org"

ruby "3.2.3"

gem "rails", "~> 7.1.6"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "devise"
gem "devise-jwt", "~> 0.12"
gem "pundit", "~> 2.4"
gem "pagy", "~> 9.3"
gem "rails-i18n", "~> 7.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "faker"
  gem "brakeman", require: false
end

group :development do
  gem "web-console"
  gem "annotate", require: false
end

group :test do
  gem "capybara"
end
