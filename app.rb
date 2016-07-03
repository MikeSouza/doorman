require 'rubygems'
require 'sinatra/base'
require 'twilio-ruby'
require 'pp'

module Doorman
  class TwilioService < Sinatra::Base
    def initialize(config)
      @cnf = config
      pp @cnf
    end

    configure do
      mime_type :twiml, 'text/xml'
    end

    before do
      #content_type 'text/html'
      #content_type :twiml
    end

    def identify_caller(params)
      number = params['From']
      
      user =
        if @cnf['phone_numbers'].has_key?(number)
          user_id = @cnf['phone_numbers'][number]
          @cnf['users'][user_id]
        else
          {'name' => 'Unknown Caller', 'is_admin' => false}
        end
    end

    def handle_incoming(params)
      user = identify_caller(params)

      if user['is_admin']
        redirect_incoming('admin')
      else
        redirect_incoming('menu')
      end
    end

    def gather_menu_option(params)
      Twilio::TwiML::Response.new do |r|
        r.Gather :numDigits => '1', :action => '/incoming/menu/handle-option' do |g|
          g.Say "Hello, you have reached the automated door answering system for #{@cnf['greeting']['name']}."
          g.Say 'To request entry, press 1.'
          g.Say 'To leave a message, press 2.'
          g.Say 'To start over, press any other key.'
        end
      end.text
    end

    def handle_menu_option(params)
      if params['Digits'] == '1'
        return gather_passcode(params)
      elsif params['Digits'] == '2'
        return record_message(params)
      else
        return redirect_incoming('menu')
      end
    end

    def redirect_incoming(uri)
      return Twilio::TwiML::Response.new do |r|
        r.Redirect "/incoming/#{uri}"
      end.text
    end

    def record_message(params)
      Twilio::TwiML::Response.new do |r|
        #r.Say 'This feature is not implemented.'
        r.Say 'Record your message after the beep.'
        r.Record :maxLength => '20', :action => '/incoming/recording'
      end.text
    end

    def gather_recording_option(params)
      Twilio::TwiML::Response.new do |r|
        r.Say "Message recorded."
        r.Gather :numDigits => '1', :action => '/incoming/recording/handle-option' do |g|
          g.Say 'To listen to your message, press 1.'
          g.Say 'To delete this message and record again, press 2.'
          g.Say 'To accept your message and quit, press any other key.'
        end
      end.text
    end

    def handle_recording_option(params)
      # TODO Implement recording options
    end

    def gather_passcode(params)
      Twilio::TwiML::Response.new do |r|
        r.Gather :numDigits => '4', :action => '/incoming/handle-passcode' do |g|
          g.Say 'Please enter passcode.'
        end
      end.text
    end

    def handle_passcode(request, params)
      puts 'Failed to gather passcode.' unless params.key?('Digits')

      if @cnf['passcodes'].has_key?(params['Digits'])
        Twilio::TwiML::Response.new do |r|
          r.Play "#{request.base_url}/AccessGranted.mp3"
          r.Play :digits => 'ww9'
        end.text
      else
        Twilio::TwiML::Response.new do |r|
          r.Play "#{request.base_url}/AccessDenied.mp3"
          r.Play :digits => 'www'
          r.Say 'Goodbye!'
          r.Play :digits => '4'
        end.text
      end
    end

    post '/incoming/recording/handle-option' do
      handle_recording_option(params)
    end

    post '/incoming/recording' do
      gather_recording_option(params)
    end

    post '/incoming/handle-passcode' do
      handle_passcode(request, params)
    end

    post '/incoming/menu/handle-option' do
      handle_menu_option(params)
    end

    post '/incoming/menu' do
      gather_menu_option(params)
    end

    post '/incoming/admin' do
      # TODO Implement admin menu, for now use default menu
      gather_menu_option(params)
    end

    post '/incoming' do
      handle_incoming(params)
    end

    get '/' do
      erb :index
    end
  end

end
