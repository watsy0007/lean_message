require 'spec_helper'

describe LeanMessage do
  it 'can setup app id and key' do
    id = 'test id'
    key = 'test key'
    Lm.setup app_id: id, app_key: key
    expect(Lm.config[:app_id]).to eq id
    expect(Lm.config[:app_key]).to eq key
  end

  context 'in test app' do
    before {
      load_test_config
    }
    let(:conn) { Lm.get_conn }

    it 'create conversation' do
      opts = {unique: true}
      jb = Lm.create_conv(['a', 'b'], opts)
      expect(jb['objectId']).to_not be_nil
      # todo 不支持REST unique 
      # https://leancloud.cn/docs/realtime_v2.html#普通对话_Normal_Conversation_ 
      #jb1 = Lm.create_conv(["BillGates", "SteveJobs"], opts)
      #expect(jb1['objectId']).to eq jb['objectId']
    end

    # todo 如何获取某client相关的所有回话呢？

    it 'get conversation messages' do
      ua = 'a'
      ub = 'b'
      conv_id = Lm.create_conv([ua, ub])['objectId']
      msg = "这是一个纯文本#{Time.now.to_i}"
      resp = Lm.post_msg(conv_id, ua, msg) 
      messages = Lm.get_messages(conv_id)
      size = messages.size
      byebug
      expect(size).to be >= 1
      lm = messages[0]
      r1 = Lm.del_msg(lm['conv-id'], lm['msg-id'], lm['timestamp'])
      messages = Lm.get_messages(conv_id)
      size1 = messages.size
      expect(size1).to be < size
    end

    it 'create message' do
      ua = 'a'
      ub = 'b'
      conv_id = Lm.create_conv([ua, ub])['objectId']
      msg = "这是一个纯文本#{Time.now.to_i}"
      resp = Lm.post_msg(conv_id, ua, msg) 
      expect(resp.empty?).to be_truthy
    end

    it 'get unread' do
      body = conn.get("rtm/messages/unread/testcid").body
      jb = JSON.parse(body)
      expect(jb['count']).to be >= 0
    end
  end
end

#{"msg-id"=>"ULNSBP1lRPizBecMBFrWxw", "conv-id"=>"57ac2ac85bbb500062b3723c00000000", "is-conv"=>true, "from"=>"a", "bin"=>false, "timestamp"=>1470900936468, "is-room"=>false, "from-ip"=>nil, "to"=>"57ac2ac85bbb500062b3723c", "data"=>{"_lctype"=>-1, "_lctext"=>"这是一个纯文本1470900940"}}
