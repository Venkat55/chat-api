require 'sinatra'
require 'mongoid'
require 'rack'
require 'rack/contrib'

# parse json body in request
use Rack::JSONBodyParser

# load mongodb config
Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))
Mongoid.use_utc = true

# Message model
class Message
  include Mongoid::Document
  LIMIT = 100
  TIME_SPAN_IN_DAYS = 30.days

  field :from, type: String
  field :to, type: String
  field :content, type: String
  field :created_at, type: DateTime

  def self.get_messages(options = {})
    limit = options[:limit] || LIMIT
    time_span_in_days = options[:time_span_in_days] || TIME_SPAN_IN_DAYS
    if options[:all]
      Message.where(:created_at.gte => DateTime.now.utc - time_span_in_days).limit(limit).to_json
    else
      raise 'Please send both sender & recipient names to fetch the message!' unless %i[sender recipient].all? do |k|
                                                                                       options.key? k
                                                                                     end

      query_param = {
        from: options[:sender],
        to: options[:recipient],
        :created_at.gte => DateTime.now.utc - time_span_in_days
      }
      Message.where(query_param).limit(limit).to_json
    end
  end
end

# validation methods
def validate_recent_messages_params(params)
  errors = []
  if !params[:time_span_in_days].nil? && params[:time_span_in_days].match(/^(\d)+$/).nil?
    errors.push('Parameter time_span_in_days should be an integer.')
  end
  errors.push('Parameter limit should be an integer.') if !params[:limit].nil? && params[:limit].match(/^(\d)+$/).nil?
  raise StandardError.new, errors unless errors.empty?
end

def get_error_message(key, value)
  if value.nil?
    "Parameter #{key} should be present."
  elsif (value.is_a? String) && value.empty?
    "Parameter #{key} cannot be empty."
  elsif !(value.is_a? String)
    "Parameter #{key} should be a string."
  end
end

def validate_send_message_params(params)
  errors = []
  errors.push(get_error_message('from', params[:from]))
  errors.push(get_error_message('to', params[:to]))
  errors.push(get_error_message('content', params[:content]))
  raise StandardError.new, errors.compact unless errors.compact.empty?
end

# routes
post '/send_message' do
  accepted_params = %w[from to content]
  message_params = params.slice(*accepted_params).merge(created_at: DateTime.now.utc)
  validate_send_message_params(message_params)
  Message.create!(message_params)
  { message: 'Message sent successfully!' }.to_json
rescue StandardError => e
  halt 422, { message: e.message }.to_json
end

get '/recent_messages/from/:sender/to/:recipient' do
  accepted_params = %w[recipient sender limit time_span_in_days]
  message_params = params.slice(*accepted_params)
  validate_recent_messages_params(message_params)
  options = {
    sender: message_params[:sender],
    recipient: message_params[:recipient]
  }
  options[:limit] = message_params[:limit].to_i unless message_params[:limit].nil?
  unless message_params[:time_span_in_days].nil?
    options[:time_span_in_days] =
      message_params[:time_span_in_days].to_i.days
  end
  Message.get_messages(options)
rescue StandardError => e
  halt 422, { message: e.message }.to_json
end

get '/recent_messages/all' do
  accepted_params = %w[limit time_span_in_days]
  message_params = params.slice(*accepted_params)
  validate_recent_messages_params(message_params)
  options = {
    all: true
  }
  options[:limit] = message_params[:limit].to_i unless message_params[:limit].nil?
  unless message_params[:time_span_in_days].nil?
    options[:time_span_in_days] =
      message_params[:time_span_in_days].to_i.days
  end
  Message.get_messages(options)
rescue StandardError => e
  halt 422, { message: e.message }.to_json
end

not_found do
  halt 404, { message: 'Page Not Found!' }.to_json
end
