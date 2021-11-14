source 'https://rubygems.org'

ruby '3.0.2'

gem 'rails', '~> 6.1.4'

gem 'bootsnap', require: false
gem 'pg'
gem 'puma'

gem 'lograge'

gem 'bcrypt'
gem 'date_validator'
gem 'i18n-backend-side_by_side'
gem 'rails-i18n'

gem 'rack-status'
gem 'rack-cors'

gem 'ros-apartment', require: 'apartment'
gem 'paranoia'
gem 'phony_rails'
gem 'tod'

gem 'activeadmin'
gem 'cancancan'
gem 'invisible_captcha'
gem 'ransack'
gem 'formtastic', '~> 4.0'

gem 'simple_form'
gem 'inline_svg'
gem 'slim'

gem 'webpacker'

gem 'importmap-rails'
gem 'hotwire-rails'
gem 'tailwindcss-rails'
gem 'turbo-rails', '~> 0.8' # 7.1.1 yanked

gem 'sidekiq'
gem 'sidekiq-scheduler'

gem 'exception_notification'
gem 'exception_notification-rake'

gem 'faraday'
gem 'faraday-cookie_jar'

gem 'gibbon'
gem 'icalendar'
gem 'image_processing', '~> 1.2'
gem 'mini_magick'
gem 'prawn'
gem 'prawn-table'
gem 'public_suffix'
gem 'rubyXL'
gem 'rexml'

gem 'postmark-rails'
gem 'premailer-rails'
gem 'liquid'

gem 'cld'

gem 'camt_parser'
gem 'epics'
gem 'rqrcode'
gem 'countries'

gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sentry-sidekiq'

gem 'kramdown'

group :production do
  gem 'aws-sdk-s3', require: false
  gem 'redis'
  gem 'barnes' # Heroku metrics
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'byebug'
  gem 'pdf-inspector', require: 'pdf/inspector'
  gem 'rspec-rails'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'bullet'
  gem 'letter_opener'
  gem 'spring-commands-rspec'
end

group :test do
  gem 'launchy'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'capybara'
  gem 'capybara-email'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end
