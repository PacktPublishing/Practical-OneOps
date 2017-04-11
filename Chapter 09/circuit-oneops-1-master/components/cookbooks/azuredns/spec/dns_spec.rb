# **Rubocop Suppression**
# rubocop:disable LineLength

require File.expand_path('../../libraries/dns.rb', __FILE__)
require File.expand_path('../../libraries/record_set.rb', __FILE__)
require 'json'
require 'rest-client'

describe AzureDns::DNS do
  before do
    platform_resource_group = 'azure_resource_group'
    token = '<DUMMY_TOKEN>'
    dns_attributes = {
      'tenant_id' => '<TENANT_ID>',
      'client_id' => '<CLIENT_ID>',
      'client_secret' => '<CLIENT_SECRET>',
      'subscription' => '<SUBSCRIPTION_ID>',
      'zone' => '<COM>'
    }
    @dns = AzureDns::DNS.new(platform_resource_group, token, dns_attributes)
  end

  describe '#create_zone' do
    it 'does not raise error when zone already exist' do
      allow(@dns.zone).to receive(:check_for_zone) { true }
      expect { @dns.create_zone }.to_not raise_error('no backtrace')
    end

    it 'creates new zone' do
      allow(@dns.zone).to receive(:check_for_zone) { false }
      allow(@dns.zone).to receive(:create) {}
      expect { @dns.create_zone }.to_not raise_error('no backtrace')
    end
  end

  describe '#get_record_type' do
    it 'returns A type of the record' do
      records = ['1.2.3.5']
      expect(@dns.get_record_type('Azure', records)).to eq('a')
    end

    it 'returns CNAME type of the record' do
      records = ['contoso.com']
      expect(@dns.get_record_type('Azure', records)).to eq('cname')
    end

    it 'sets A type dns records in recordset' do
      records = ['1.2.3.5']
      allow(@dns.recordset).to receive(:get_existing_records_for_recordset) { records }
      entries = [{ 'name' => 'Azure', 'values' => '1.2.3.4' }]
      expect { @dns.set_dns_records(entries, 'RS_Name', 300) }.to_not raise_error('no backtrace')
    end
  end

  describe '#set_cname_type_records' do
    it 'sets CNAME type dns records in recordset' do
      records = ['1.2.3.5']
      allow(@dns.recordset).to receive(:get_existing_records_for_recordset) { records }
      entries = [{ 'name' => 'Azure', 'values' => 'contoso.com' }]
      expect { @dns.set_dns_records(entries, 'RS_Name', 300) }.to_not raise_error('no backtrace')
    end

    it 'sets CNAME type dns records in recordset' do
      records = ['contoso.com']
      allow(@dns.recordset).to receive(:set_records_on_record_set) {}
      expect { @dns.set_cname_type_records(records, 'create', records, 'Azure', 300) }.to_not raise_error('no backtrace')
    end

    it 'removes CNAME type dns records from recordset' do
      records = ['contoso.com']
      allow(@dns.recordset).to receive(:remove_record_set) {}
      expect { @dns.set_cname_type_records(records, 'remove', records, 'Azure', 300) }.to_not raise_error('no backtrace')
    end

    it 'skips CNAME type dns records in recordset' do
      records_list = [['contoso.com']]
      record = ['contoso.com']
      allow(@dns.recordset).to receive(:set_records_on_record_set) {}
      expect { @dns.set_cname_type_records(records_list, 'create', record, 'Azure', 300) }.to_not raise_error('no backtrace')
    end
  end

  describe '#set_a_type_records' do
    it 'skips A type dns records in recordset' do
      records = ['1.2.3.5']
      allow(@dns.recordset).to receive(:set_records_on_record_set) {}
      expect { @dns.set_a_type_records(records, 'create', records, 'Azure', 300) }.to_not raise_error('no backtrace')
    end

    it 'removes A type specific dns recordset' do
      records = []
      allow(@dns.recordset).to receive(:remove_record_set) {}
      expect { @dns.set_a_type_records(records, 'remove', records, 'Azure', 300) }.to_not raise_error('no backtrace')
    end

    it 'sets the specific A type dns record in recordset' do
      records_list = ['1.2.3.4', '1.2.3.5']
      record = ['1.2.3.6']
      allow(@dns.recordset).to receive(:remove_record_set) {}
      expect { @dns.set_a_type_records(records_list, 'create', record, 'Azure', 300) }.to_not raise_error('no backtrace')
    end
  end
end
