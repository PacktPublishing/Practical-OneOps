require 'json'
require 'rest-client'
require File.expand_path('../../libraries/zone.rb', __FILE__)

describe AzureDns::Zone do
  before :each do
    platform_resource_group = '<RESOURCE-GROUP-NAME>'
    token = '<AUTH-TOKEN>'
    dns_attributes = {
      tenant_id: '<TENANT-ID>',
      client_id: '<CLIENT-ID>',
      client_secret: '<CLIENT-SECRET>',
      subscription: '<SUBSCRIPTION-ID>',
      zone: '<ZONE-NAME>' }
    @zone = AzureDns::Zone.new(dns_attributes, token, platform_resource_group)
  end

  describe '#create' do
    it 'creates zone' do
      allow(RestClient).to receive(:put).and_return({ code: 200 }.to_json)
      expect { @zone.create }.to_not raise_error(Exception)
    end

    it 'does not create zone' do
      e = RestClient::Exception.new(nil, 404)
      allow(RestClient).to receive(:put).and_raise(e)
      expect { @zone.create }.to raise_error(Exception)
    end
  end

  describe '#check_for_zone' do
    it 'varifies that zone exists' do
      allow(RestClient).to receive(:get).and_return({ code: 200 }.to_json)
      expect(@zone.check_for_zone).to be(true)
    end

    it 'varifies that zone does not exist' do
      e = RestClient::Exception.new(nil, 404)
      allow(RestClient).to receive(:get).and_raise(e)
      expect(@zone.check_for_zone).to be(false)
    end

    it 'varifies that status code other than 404 causes exception' do
      e = RestClient::Exception.new(nil, 500)
      allow(RestClient).to receive(:get).and_raise(e)
      expect { @zone.check_for_zone }.to raise_error(Exception)
    end
  end
end
