require 'rest-client'
require 'json'
require ::File.expand_path('../../libraries/token.rb', __FILE__)

# **Rubocop Suppression**
# rubocop:disable LineLength

describe 'Azuredns::Token' do
  token = AzureDns::Token.new('<TENANT-ID>', '<CLIENT-ID>', '<CLIENT-SECRET>')

  it 'returns token' do
    allow(RestClient).to receive(:post)
      .and_return({ access_token: 'i-am-a-token' }.to_json)
    expect(token.generate_token).to eq('Bearer i-am-a-token')
  end

  it 'raises exception due to error in response' do
    allow(RestClient).to receive(:post)
      .and_return({ error: 'invalid_grant' }.to_json)
    expect { token.generate_token }.to raise_error(Exception)
  end

  it 'verifies the proxy settings' do
    token = AzureDns::Token.new('<TENANT-ID>', '<CLIENT-ID>', '<CLIENT-SECRET>', 'https://proxyxite.com')
    allow(RestClient).to receive(:post)
      .and_return({ access_token: 'i-am-a-token' }.to_json)
    token.generate_token
    expect(RestClient.proxy).to eq('https://proxyxite.com')
  end
end
