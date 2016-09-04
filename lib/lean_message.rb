# -*- coding: utf-8 -*-
require 'active_support'
require 'active_support/core_ext'
require 'active_support/lib'
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
    opts = ActiveSupport::HashWithIndifferentAccess(opts)
    [:app_id, :app_key].each do |key|
      raise "Blank id: #{key}!" if opts[key].blank?
    end
    @config = opts
  end

  def conn
    @conn ||= begin
                puts default_headers
                Faraday.new(BASE_URI, headers: default_headers)
              end
  end

  def master_conn
    @master_conn ||= begin
                       Faraday.new(BASE_URI, headers: master_headers)
                     end
  end

  def config
    @config ||= {}
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
    body = {username: username, password: password}.merge(opts)
    resp = conn.post 'users', body.to_json
    JSON.parse(resp.body)
  end

  def users
    resp = conn.get 'users'
    JSON.parse(resp.body)
  end

  def create_conv(members, c = '', opts = {})
    c = c.empty? ? '' : members[0]
    body = {unique: true, m: members, c: c}.merge(opts)
    resp = conn.post 'classes/_Conversation', body.to_json
    JSON.parse(resp.body)
  end

  def conversations
    resp = conn.get 'classes/_Conversation'
    JSON.parse(resp.body)
  end

  # post normal msg
  def post_msg(conv_id, from, text, opts = {})
    msg = { _lctype: -1, _lctext: text }
    attrs = {from_peer: from, message: msg, conv_id: conv_id, transient: false}
    resp = master_conn.post 'rtm/messages', attrs.to_json
    JSON.parse(resp.body)
  end

  def get_messages(conv_id, opts = {})
    resp = master_conn.get 'rtm/messages/logs', {convid: conv_id, transient: false}
    JSON.parse(resp.body)
  end

  def del_msg(conv_id, msgid, timestamp)
    opts = {convid: conv_id, msgid: msgid, timestamp: timestamp}
    master_conn.delete 'rtm/messages/logs', opts
  end
end

LM = LeanMessage unless defined?(LM)
