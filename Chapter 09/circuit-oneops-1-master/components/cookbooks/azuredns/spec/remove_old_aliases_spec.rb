require 'json'
require File.expand_path('../../libraries/dns.rb', __FILE__)
require File.expand_path('../../libraries/record_set.rb', __FILE__)
describe AzureDns::DNS do
  file_path = File.expand_path('remove_old_aliases_data.json', __dir__)
  file = File.open(file_path)
  contents = file.read
  node_attr = JSON.parse(contents)
  cloud_service = node_attr['workorder']['services']['dns']['azure']
  service_attrs = cloud_service['ciAttributes']
  token = node_attr['azure_rest_token']
  resource_group = node_attr['platform-resource-group']
  dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)

  describe '#normalize_customer_domain' do
    customer_domain = dns_obj.normalize_customer_domain(node_attr['customer_domain'])
    it 'returns the customer domain with "." in it' do
      expect(customer_domain).to eq('.env.asm.org.oneops.com')
    end
    it 'throws an exception that the customer domain is required' do
      expect { dns_obj.normalize_customer_domain(nil) }.to raise_exception(Exception)
    end
  end

  describe '#remove_zone_name_from_customer_domain' do
    zone_name = node_attr['workorder']['services']['dns']['azure']['ciAttributes']['zone']
    customer_domain = dns_obj.remove_zone_name_from_customer_domain('.env.asm.org.oneops.com', zone_name)
    it 'removes the zone name from the customaer domain' do
      expect(customer_domain).to eq('.env.asm.org')
    end
    it 'does not remove the zone name from the customaer domain' do
      expect(customer_domain).to_not eq('.env.asm.org.oneops.com')
    end
  end

  describe '#check_cloud_dns_id' do
    it 'does not raise error if cloud dns id is not nil' do
      expect { dns_obj.check_cloud_dns_id(service_attrs, cloud_service) }.to_not raise_error
    end
    it 'throws exception when cloud_dns_id is empty' do
      service_attrs['cloud_dns_id'] = nil
      expect { dns_obj.check_cloud_dns_id(service_attrs, cloud_service) }.to raise_exception(Exception)
      service_attrs['cloud_dns_id'] = "asm.org"
    end
  end

  describe 'entrypoint_exists' do
    hostname_entry = dns_obj.entrypoint_exists(node_attr['workorder']['payLoad'])
    it 'expects the hostname entry to be false if payload has Entrypoint key' do
      expect(hostname_entry).to be_falsey
    end
  end
  describe '#get_all_aliases' do
    it 'returns the hash of all aliases' do
      types = ['aliases', 'current_aliases', 'full_aliases', 'current_full_aliases']
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      hash_of_all_aliases = dns_obj.get_all_aliases(node_attr['workorder']['rfcCi'], false, types)
      expect(hash_of_all_aliases).to eq([{:name=>"aliases", :values=>["alias1", "alias2"]},
                                             {:name=>"current_aliases", :values=>["alias2"]},
                                             {:name=>"full_aliases", :values=>["full-alias1", "full-alias2"]},
                                             {:name=>"current_full_aliases", :values=>["full-alias2"]}])
    end
    it 'gives nil when hostname entry is true' do
      types = ['aliases', 'current_aliases', 'full_aliases', 'current_full_aliases']
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      hash_of_all_aliases = dns_obj.get_all_aliases(node_attr['workorder']['rfcCi'], true, types)
          expect(hash_of_all_aliases).to eq([])
    end
    it ' rescue JSON Parse error' do
            node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"\"]"
            types = ['aliases', 'current_aliases', 'full_aliases', 'current_full_aliases']
            dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
            hash_of_all_aliases = dns_obj.get_all_aliases(node_attr['workorder']['rfcCi'], false, types)
            expect { hash_of_all_aliases }.to_not raise_error
            node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
          end
  end

  describe '#remove_all_aliases' do
    dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
    hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
    it 'deletes current/active aliases from aliases' do
     expect(hash_of_removed_aliases).to eq([{:name=>"aliases", :values=>["alias1"]}, {:name=>"full_aliases", :values=>["full-alias1"]}])
    end
    it 'returns emty string when aliases are nil' do
            dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
            node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"]"
            hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
            aliases = []
            hash_of_removed_aliases.each do |entry|
              name = entry[:name]
              if name == "aliases"
                aliases = entry[:values]
              end
            end
            expect(aliases).to eq([""])
            node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
    end
    it 'return complete aliases to be deleted when current aliases are nil' do
            dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
            node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"\"]"
            hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
            aliases = []
            hash_of_removed_aliases.each do |entry|
              name = entry[:name]
              if name == "aliases"
                aliases = entry[:values]
              end
            end
            expect(aliases).to eq(["alias1", "alias2"])
            node_attr['workorder']['rfcCi']['ciAttributes']['aliases'] = "[\"alias2\"]"
          end
  end

  describe '#get_entries' do
    entries_response = ['contoso.com']
    entries_nil = nil

      it 'returns entries on the basis of aliases with priority 0' do
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
        aliases = []
        hash_of_removed_aliases.each do |entry|
          name = entry[:name]
          if name == "aliases"
            aliases = entry[:values]
          end
        end
        entries = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        expect(entries).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" }])
      end
      it 'returns entries on the basis of aliases with priority 1' do
        priority = '1'
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
        aliases = []
        hash_of_removed_aliases.each do |entry|
          name = entry[:name]
          if name == "aliases"
            aliases = entry[:values]
          end
        end
        entries = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        expect(entries).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" },
                               { name: "alias1.env", values: "contoso.com" }])
      end

      it 'returns emty entries array when value is nil' do
        priority = "0"
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_nil }
        hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
        aliases = []
        hash_of_removed_aliases.each do |entry|
          name = entry[:name]
          if name == "aliases"
            aliases = entry[:values]
          end
        end
        entries = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        expect(entries).to eq([])
      end

      it 'returns emty entries array when aliases are nil' do
        priority = "0"
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"\"]"
        hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
        aliases = []
        hash_of_removed_aliases.each do |entry|
          name = entry[:name]
          if name == "aliases"
            aliases = entry[:values]
          end
        end
        expect(dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)).to eq([])
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['aliases'] = "[\"alias1\",\"alias2\"]"
      end
  end

  describe '#get_updated_entries' do
      entries_response = ['oneops.com']
      it 'returns entries when full aliases are not nil' do
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
        hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
        aliases = []
        full_aliases = []
        hash_of_removed_aliases.each do |entry|
          name = entry[:name]
          if name == "aliases"
            aliases = entry[:values]
          end
          if name == "full_aliases"
            full_aliases = entry[:values]
          end
        end
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        entries_for_get_entries_method = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        entries = dns_obj.get_updated_entries(entries_for_get_entries_method, full_aliases)
        expect(entries).to eq([{ name: "alias1.env.asm.org", values: "oneops.com" },
                               { name: "full-alias1", values: "oneops.com" }])
      end
      it 'does not raise error when full aliases are nil' do
        dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[]"
        hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
        aliases = []
        full_aliases = []
        hash_of_removed_aliases.each do |entry|
          name = entry[:name]
          if name == "aliases"
            aliases = entry[:values]
          end
          if name == "full_aliases"
            full_aliases = entry[:values]
          end
        end
        priority = node_attr['workorder']['cloud']['ciAttributes']['priority']
        entries_for_get_entries_method = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
        expect { dns_obj.get_updated_entries(entries_for_get_entries_method, full_aliases) }.to_not raise_error('Nil Check')
        node_attr['workorder']['rfcCi']['ciBaseAttributes']['full_aliases'] = "[\"full-alias1\",\"full-alias2\"]"
      end
  end

  describe '#delete_record_set' do
    it 'returns the entries to be removed from azure' do
      responsefromremoverecordset = ''
      entries_response = ['contoso.com']
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      allow(dns_obj.recordset).to receive(:get_existing_records_for_recordset) { entries_response }
      allow(dns_obj.recordset).to receive(:remove_record_set) { responsefromremoverecordset }
      priority = "0"
      hash_of_removed_aliases = dns_obj.remove_all_aliases(node_attr['workorder']['rfcCi'], false)
      aliases = []
      full_aliases = []
      hash_of_removed_aliases.each do |entry|
        name = entry[:name]
        if name == "aliases"
          aliases = entry[:values]
        end
        if name == "full_aliases"
          full_aliases = entry[:values]
        end
      end
      entries_for_get_entries_method = dns_obj.get_entries('.env.asm.org', priority, service_attrs['cloud_dns_id'], aliases)
      entries = dns_obj.get_updated_entries(entries_for_get_entries_method, full_aliases)
      result = dns_obj.delete_record_set(entries)
      expect(result).to eq([{ name: "alias1.env.asm.org", values: "contoso.com" }, { name: "full-alias1", values: "contoso.com" }])
    end
    it 'gives empty string when entries are nil' do
      dns_obj = AzureDns::DNS.new(resource_group, token, service_attrs)
      entries = []
      expect(dns_obj.delete_record_set(entries)).to eq([])
    end
  end
end
