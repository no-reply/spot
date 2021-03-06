ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

if ENV['COVERAGE'] || ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter if ENV['TRAVIS']
  SimpleCov.start 'rails'
end

require 'rspec/rails'
require 'factory_bot_rails'
require 'ffaker'
require 'active_fedora/cleaner'
require 'capybara/rspec'
require 'capybara/rails'
require 'capybara-screenshot/rspec'

# copied selenium chrome drive config from samvera/hyrax/spec/spec_helper.rb
#
# @note In January 2018, TravisCI disabled Chrome sandboxing in its Linux
#       container build environments to mitigate Meltdown/Spectre
#       vulnerabilities, at which point Hyrax could no longer use the
#       Capybara-provided :selenium_chrome_headless driver (which does not
#       include the `--no-sandbox` argument).
Capybara.register_driver :selenium_chrome_headless_sandboxless do |app|
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << '--headless'
  browser_options.args << '--disable-gpu'
  browser_options.args << '--no-sandbox'
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

Capybara.default_driver = :rack_test # This is a faster driver
Capybara.javascript_driver = :selenium_chrome_headless_sandboxless # This is slower

# since we've created a custsom driver (that is a wrapper around a Selenium
# driver), we need to tell capybara-screenshot how to take a screenshot
# (which is copied from the Selenium configuration)
Capybara::Screenshot.register_driver(:selenium_chrome_headless_sandboxless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.prune_strategy = :keep_last_run

# require support files
Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.order = :random
  Kernel.srand config.seed

  ##
  # rspec/rails config

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # /end rspec/rails
  ##

  config.include Warden::Test::Helpers
  config.include Devise::Test::ControllerHelpers, type: :controller

  # FactoryBot setup
  config.include FactoryBot::Syntax::Methods

  config.use_transactional_fixtures = false

  config.render_views = true

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    ActiveFedora::Cleaner.clean!
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(clean: true) do
    ActiveFedora::Cleaner.clean!
  end

  config.before(js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
