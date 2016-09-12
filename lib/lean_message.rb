# -*- coding: utf-8 -*-
require 'active_support'
require 'active_support/core_ext'
require 'faraday'
require 'faraday_middleware'

module LeanMessage
  API_VERSION = '1.1'
  #中国节点：https://api.leancloud.cn
  #美国节点：https://us-api.leancloud.cn
  BASE_URI = "https://api.leancloud.cn/#{API_VERSION}"
  module_function

  attr_accessor :config, :conn, :master_conn

  def setup
    opts = {}
    opts = yield(self) if block_given?
    raise "config error" unless opts.is_a?(Hash)
    opts = ActiveSupport::HashWithIndifferentAccess.new(opts)
    [:app_id, :app_key].each do |key|
      raise "Blank id: #{key}!" if opts[key].blank?
    end
    @config = opts
  end

  def conn
    Faraday.new(BASE_URI, headers: default_headers.merge(debug_headers))
  end

  def master_conn
    Faraday.new(BASE_URI, headers: master_headers.merge(debug_headers))
  end

  def config
    @config ||= {}
  end

  def debug_headers
    return {} if config[:debug_mode].blank?
    {'X-LC-Prod' => '0'}
  end

  def default_headers
    {
      'X-LC-Id' => config[:app_id],
      'X-LC-Key' => config[:app_key],
      'Content-Type' => 'application/json'
    }
  end

  def master_headers
    {
      'X-LC-Id' => config[:app_id],
      'X-LC-Key' => "#{config[:master_key]},master",
      'Content-Type' => 'application/json'
    }
  end

  def create_user(username, password = '', opts = {})
    body = {username: username.to_s, password: password.to_s}.merge(opts)
    resp = conn.post 'users', body.to_json
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def users(opts = {})
    opts = {where: opts} if opts.present?
    resp = conn.get 'users', opts
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def user(opts = {})
    query = {}
    query.merge!({username: opts[:username]}) if opts[:username].present?
    query.merge!({objectId: opts[:objectId]}) if opts[:objectId].present?
    resp = conn.get 'users', {where: query }
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def del_user(objectId)
    resp = master_conn.delete "users/#{objectId}"
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def create_conv(members, c = '', opts = {})
    body = {unique: true, m: members.map(&:to_s), c: c.to_s, tr: false, name: members.join('_'), mu: []}.merge(opts)
    resp = conn.post 'classes/_Conversation', body.to_json
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def conversations(opts = {})
    opts = {where: opts} if opts.present?
    resp = conn.get 'classes/_Conversation', opts
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def conversation(opts = {})
    query = {}
    query.merge!(m: opts[:m]) if opts[:m].present?
    query.merge!(c: opts[:c]) if opts[:c].present?
    query = { where: query }if query.present?
    resp = conn.get 'classes/_Conversation', query
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def del_conv(objectId)
    resp = master_conn.delete "classes/_Conversation/#{objectId}"
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  # post normal msg
  def post_msg(conv_id, from, text, opts = {})
    msg = { _lctype: -1, _lctext: text }
    msg = msg.merge({_lcattrs: opts}) if opts.present?
    attrs = {from_peer: from.to_s, message: msg, conv_id: conv_id, transient: false, no_sync: true}
    resp = master_conn.post 'rtm/messages', attrs.to_json
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def update_msg(is_read, read_time, opts = {})
    return if opts.blank?
    opts.merge!('act-at' => read_time.to_datetime.strftime('%Q'), 'act-ua' => 'migrate') if is_read
    resp = master_conn.put 'rtm/messages/logs', opts.to_json
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def message(opts = {})
    resp = master_conn.get 'rtm/messages/logs', opts
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def get_messages(conv_id, opts = {})
    resp = master_conn.get 'rtm/messages/logs', {convid: conv_id, transient: false}
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def messages(opts = {})
    opts = {where: opts} if opts.present?
    resp = master_conn.get 'rtm/messages/logs', opts
    JSON.parse(resp.body)
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end

  def del_msg(conv_id, msgid, timestamp)
    opts = {convid: conv_id, msgid: msgid, timestamp: timestamp}
    master_conn.delete 'rtm/messages/logs', opts
  rescue Faraday::ConnectionFailed => e
    puts e
    sleep(1)
    retry
  end
end

LM = LeanMessage unless defined?(LM)
