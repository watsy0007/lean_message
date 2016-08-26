$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'lean_message'
require 'json'
require 'byebug'

def load_test_config
  aid = ENV['APP_ID'] || 'TEEzWr1i9oo01mf3El8aUigR-gzGzoHsz'
  akey = ENV['APP_KEY'] || 'OnQuOz1dmEtFNDysWK5kMFm9'
  mkey = ENV['MASTER_KEY'] || '1S1y5Y7RblN7nviXgCT9yD2J'
  Lm.setup app_id: aid, app_key: akey, master_key: mkey
end

#module APISupport
  #def response_json
    #JSON.parse(response.body)
  #end
#end

#RSpec.configure do |config|
  #config.include APISupport #, type: :request #, file_path: %r{ /spec\/requests\/v1/ }
#end
