# config.ru

require 'bundler'
require 'rubygems'
require 'sinatra'
require 'twilio-ruby'
require 'yaml'
require File.expand_path('app.rb', __dir__)

# Get the environment set by the application server (i.e. :production, :development, etc.)
environment = ENV['RACK_ENV'].to_sym

# Only load gems specific to environment
Bundler.require(:default, environment)

twilio = YAML::load_file('twilio.yml')

puts "RACK_ENV = #{environment}"

# Configure environment specific middleware
case environment
when :production
  auth_token = twilio[environment.to_s]['auth_token']
  use Rack::TwilioWebhookAuthentication, auth_token, /\/incoming/
when :development
  use Rack::ShowExceptions
else
  $stderr.puts "Unknown environment: #{environment}"
end

config = YAML::load_file('config.yml')

run Doorman::TwilioService.new(config)
