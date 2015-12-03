require 'spec_helper'

describe 'E-Mail Update from JIRA Webhook ' do
  include Mail::Matchers

  before(:each) do
    Mail::TestMailer.deliveries.clear
  end

  def valid_json_sample
    File.read(File.join(File.dirname(__FILE__), '..', '..', 'sample_data.json'))
  end

  def invalid_json_sample
    '{"issue": {"id": "13123","key": "PPS-123"}}'
  end

  def mock_json_data
    data = {}
    data[:issue] = {}
    data[:issue][:fields] = {}
    data[:transition] = {}

    data[:issue][:key] = 'PPS-123'
    data[:issue][:fields][:customfield_10100] = 'justin'
    data[:issue][:fields][:summary] = 'Please Fix Bug'
    data[:issue][:fields][:description] = 'The bug is that the image is one '\
                                          'pixel too wide.'
    data[:transition][:from_status] = 'Incoming'
    data[:transition][:to_status] = 'Ready'
    data[:comment] = ''

    data.to_json
  end

  it 'returns a 404 error if an invalid path is used' do
    post '/doesntexist', 'junk'
    expect(last_response.status).to be(404)
    should_not have_sent_email
  end

  it 'returns a 500 error if invalid JSON is submitted' do
    post '/emailupdate', 'junk'
    expect(last_response.status).to be(500)
    should_not have_sent_email
  end

  it 'returns a 500 error if empty JSON is submitted' do
    post '/emailupdate', '{}'
    expect(last_response.status).to be(500)
    should_not have_sent_email
  end

  it 'returns a 500 with invalid data' do
    post '/emailupdate', invalid_json_sample
    expect(last_response.status).to be(500)
    should_not have_sent_email
  end

  it 'returns a 200 with valid data' do
    post '/emailupdate', valid_json_sample
    expect(last_response.status).to be(200)
    should have_sent_email
  end

  it 'sends a useful e-mail with mock data' do
    post '/emailupdate', mock_json_data
    expect(last_response.status).to be(200)
    should have_sent_email
    should have_sent_email.from('support@example.com')
    should have_sent_email.to('justin@example.com')
    should have_sent_email.with_subject('PPS-123 (Please Fix Bug) '\
                                        'now has a status of: Ready')
  end
end
