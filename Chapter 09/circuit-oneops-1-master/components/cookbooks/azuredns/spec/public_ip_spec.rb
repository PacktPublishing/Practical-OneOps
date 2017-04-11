require 'rspec'
require 'json'
require 'ms_rest'

require ::File.expand_path('../../libraries/public_ip.rb', __FILE__)

describe 'Azuredns::public_ip' do
  file_path = File.expand_path('update_dns_on_pip_data.json', __dir__)
  file = File.open(file_path)
  contents = file.read
  node = JSON.parse(contents)

  public_ip_file_path = File.expand_path('public_ip.json', __dir__)
  public_ip_file = File.open(public_ip_file_path)
  public_ip_contents = public_ip_file.read
  pub_ip = JSON.parse(public_ip_contents)

  cloud_name = node['workorder']['cloud']['ciName']
  dns_attributes = node['workorder']['services']['dns'][cloud_name]['ciAttributes']
  subscription = dns_attributes['subscription']
  resource_group = node['platform-resource-group']
  tenant_id = dns_attributes['tenant_id']
  client_id = dns_attributes['client_id']
  client_secret = dns_attributes['client_secret']
  credentials = MsRest::TokenCredentials.new(MsRestAzure::ApplicationTokenProvider.new(tenant_id, client_id, client_secret))
  zone_name = dns_attributes['zone'].split('.').reverse.join('.').partition('.').last.split('.').reverse.join('.').tr('.', '-')

  dns_public_ip = AzureDns::PublicIp.new(resource_group,credentials , subscription, zone_name)

  describe 'PublicIp::update_dns' do
    it 'returns nil if node.app_name is "os"' do
      node['app_name'] = 'os'
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      allow(dns_public_ip.pubip).to receive(:create_update) {}
      expect(dns_public_ip.update_dns(node)).to be_nil
    end

    it 'returns nil if node.app_name is "fqdn"' do
      node['app_name'] = 'fqdn'
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      allow(dns_public_ip.pubip).to receive(:create_update) {}
      expect(dns_public_ip.update_dns(node)).to be_nil
    end

    it 'returns domain-name-label if node.app_name is "lb"' do
      node['app_name'] = 'lb'
      expect(dns_public_ip.update_dns(node)).to eq('lb-compute-1189982-1-1578346-s3rss-test-php-mysql-oneops-one')
    end
  end

  describe 'PublicIp::update_dns_for_os' do
    node['app_name'] = 'os'
    it 'returns nil if node.full_hostname is nil' do
      node['full_hostname'] = nil
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      expect(dns_public_ip.update_dns_for_os(node)).to be_nil
    end

    it 'returns nil if node.full_hostname is not nil' do
      node['full_hostname'] = 'test-php-mysql.oneops.com'
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      allow(dns_public_ip.pubip).to receive(:create_update) {}
      expect(dns_public_ip.update_dns_for_os(node)).to be_nil
    end
  end

  describe 'PublicIp::update_dns_for_fqdn' do
    node['app_name'] = 'fqdn'
    it 'returns nil if node.app_name is "fqdn"' do
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      allow(dns_public_ip.pubip).to receive(:create_update) {}
      expect(dns_public_ip.update_dns_for_fqdn(node)).to be_nil
    end

    it 'returns nil if aliases are not available' do
      node['workorder']['rfcCi']['ciAttributes']['aliases'] = "[]"
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      allow(dns_public_ip.pubip).to receive(:create_update) {}
      expect(dns_public_ip.update_dns_for_fqdn(node)).to be_nil
    end

    it 'returns nil if availability is "single"' do
      node['workorder']['box']['ciAttributes']['availability'] = 'single'
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      allow(dns_public_ip.pubip).to receive(:create_update) {}
      expect(dns_public_ip.update_dns_for_fqdn(node)).to be_nil
    end

    it 'returns lb-list if availability is "redundant"' do
      node['workorder']['box']['ciAttributes']['availability'] = 'redundant'
      allow(dns_public_ip.pubip).to receive(:check_existence_publicip) { true }
      allow(dns_public_ip.pubip).to receive(:get) { pub_ip }
      allow(dns_public_ip.pubip).to receive(:create_update) {}
      expect(dns_public_ip.update_dns_for_fqdn(node)).to eq([{"ciId"=>1189945}])
    end
  end

  describe 'PublicIp::update_dns_for_lb' do
    node['app_name'] = 'lb'
    it 'returns domain-name-label if node.app_name is "lb"' do
      expect(dns_public_ip.update_dns_for_lb(node)).to eq('lb-compute-1189982-1-1578346-s3rss-test-php-mysql-oneops-one')
    end
  end

  end