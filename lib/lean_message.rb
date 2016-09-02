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

  def setup(opts = {})
    raise "config error" unless opts.is_a?(Hash)
    [:app_id, :app_key].each do |key|
      raise "Blank id: #{key}!" if opts[key].blank?
    end
    @config = opts
  end

  def conn
    @conn ||= begin
                Faraday.new(BASE_URI, headers: default_headers)
              end
  end

  def master_conn
    @master_conn ||= begin
                       Faraday.new(BASE_URI, headers: master_headers)
                     end
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

  def create_user(username, opts = {})
    body = {username: username}.merge(opts)
    resp = conn.post 'users', body.to_json
    JSON.parse(resp.body)
  end

  def create_conv(members, opts = {})
    body = {m: members}.merge(opts)
    resp = conn.post 'classes/_Conversation', body.to_json
    JSON.parse(resp.body)
  end

  # post normal msg
  def post_msg(conv_id, from, text, opts = {})
    msg = { _lctype: -1, _lctext: text }
    attrs = {from_peer: from, message: msg, conv_id: conv_id, transient: false}
    resp = Lm.master_conn.post 'rtm/messages', attrs.to_json
    JSON.parse(resp.body)
  end

  def get_messages(conv_id, opts = {})
    resp = Lm.master_conn.get 'rtm/messages/logs', {conv_id: conv_id, transient: false}
    JSON.parse(resp.body)
  end

  def del_msg(conv_id, msgid, timestamp)
    #curl -X DELETE \
    #-G \
    #--data-urlencode 'convid=219946ef32e40c515d33ae6975a5c593' \
    #--data-urlencode 'msgid=PESlY' \
    #--data-urlencode 'timestamp=1408008498571' \
    opts = {convid: conv_id, msgid: msgid, timestamp: timestamp}
    Lm.master_conn.delete 'rtm/messages/logs', opts
  end
end

Lm = LeanMessage unless defined?(Lm)
