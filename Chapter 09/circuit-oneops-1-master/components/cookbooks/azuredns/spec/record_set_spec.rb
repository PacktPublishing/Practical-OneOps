# rubocop:disable LineLength
require File.expand_path('../../libraries/record_set.rb', __FILE__)
require 'json'
require 'rest-client'

describe AzureDns::RecordSet do
  before do
    platform_resource_group = 'azure_resource_group'
    token = '<DUMMY_TOKEN>'
    dns_attributes = {
      'tenant_id' => '<TENANT_ID>',
      'client_id' => '<CLIENT_ID>',
      'client_secret' => '<CLIENT_SECRET>',
      'subscription' => '<SUBSCRIPTION_ID>',
      'zone' => '<COM>' }
    @record_sets = AzureDns::RecordSet.new(dns_attributes,
                                           token, platform_resource_group)
  end

  describe '#get_existing_records_for_recordset' do
    it 'returns A type record for recordset' do
      file_path = File.expand_path('A_type_record_data.json', __dir__)
      file = File.open(file_path)
      dns_response = file.read
      allow(RestClient).to receive(:get) { dns_response }
      records = ['1.2.3.4']
      expect @record_sets.get_existing_records_for_recordset('A', 'RS_Name')
        .equal?(records)
    end
  end

  describe '#get_existing_records_for_recordset' do
    it 'returns CNAME type record for recordset' do
      file_path = File.expand_path('CNAME_type_record_data.json', __dir__)
      file = File.open(file_path)
      dns_response = file.read
      allow(RestClient).to receive(:get) { dns_response }
      records = ['contoso.com']
      expect @record_sets.get_existing_records_for_recordset('CNAME', 'RS_Name')
        .equal?(records)
    end
  end

  describe '#get_existing_records_for_recordset' do
    it 'raises JSON parsing error' do
      allow(RestClient).to receive(:get) {}
      allow(JSON).to receive(:parse) {}
      expect { @record_sets.get_existing_records_for_recordset('CNAME', 'RS') }
        .to raise_error('no backtrace')
    end
  end

  describe '#get_existing_records_for_recordset' do
    it 'raises an exception' do
      allow(RestClient).to receive(:get)
        .and_raise(RestClient::Exception.new(nil))
      expect { @record_sets.get_existing_records_for_recordset('A', 'RS_Name') }
        .to raise_error('no backtrace')
    end
  end

  describe '#get_existing_records_for_recordset' do
    it 'raises an exception with http_code 404' do
      allow(RestClient).to receive(:get)
        .and_raise(RestClient::Exception.new(nil, 404))
      expect { @record_sets.get_existing_records_for_recordset('A', 'RS_Name') }
        .to_not raise_error('no backtrace')
    end
  end

  describe '#set_records_on_record_set' do
    it 'sets A type records on recordset' do
      response = double
      allow(response).to receive(:code) { 200 }
      allow(RestClient).to receive(:put) { response }
      records = ['1.2.3.4', '1.2.3.5']
      expect { @record_sets.set_records_on_record_set('RS_Name', records, 'A', 300) }
        .to_not raise_error('no backtrace')
    end
  end

  describe '#set_records_on_record_set' do
    it 'sets CNAME type record on recordset' do
      response = double
      allow(response).to receive(:code) { 200 }
      allow(RestClient).to receive(:put) { response }
      records = ['contoso.com']

      expect { @record_sets.set_records_on_record_set('RS', records, 'CNAME', 300) }
        .to_not raise_error('no backtrace')
    end
  end

  describe '#set_records_on_record_set' do
    it 'raises an exception' do
      allow(RestClient).to receive(:put)
        .and_raise(RestClient::Exception.new(nil))
      records = ['1.2.3.4', '1.2.3.5']
      expect { @record_sets.set_records_on_record_set('RS_Name', records, 'A', 300) }
        .to raise_error('no backtrace')
    end
  end

  describe '#remove_record_set' do
    it 'removes recordset' do
      response = double
      allow(response).to receive(:code) { 200 }
      allow(RestClient).to receive(:delete) { response }

      expect { @record_sets.remove_record_set('Recordset_Name', 'A') }
        .to_not raise_error('no backtrace')
    end
  end

  describe '#remove_record_set' do
    it 'raises an exception' do
      allow(RestClient).to receive(:delete)
        .and_raise(RestClient::Exception.new(nil))
      expect { @record_sets.remove_record_set('Recordset_Name', 'A') }
        .to raise_error('no backtrace')
    end
  end

  describe '#remove_record_set' do
    it 'raises an exception with http code 404' do
      allow(RestClient).to receive(:delete)
        .and_raise(RestClient::Exception.new(nil, 404))
      expect { @record_sets.remove_record_set('Recordset_Name', 'A') }
        .to_not raise_error('no backtrace')
    end
  end
end
