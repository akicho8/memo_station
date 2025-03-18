source "https://rubygems.org"

ruby "3.4.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "~> 8.0.2"

# Use sqlite3 as the database for Active Record
gem "sqlite3"

# Use Puma as the app server
gem "puma", ">= 6"

# Use SCSS for stylesheets
gem "sass-rails", ">= 6"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Capistrano for deployment
group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "capistrano"
  gem "capistrano-rails"        # capistrano + capistrano-bundler
  gem "capistrano-rbenv"
end

group :development, :test do
  gem "debug"
end

group :development do
  # Access an interactive console on exception pages or by calling "console" anywhere in the code.
  gem "web-console"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler"
end

group :development, :test do
  gem "rspec-rails"
  gem "test-unit"
end

gem "slim-rails"
gem "acts-as-taggable-on"
gem "rails_autolink"
