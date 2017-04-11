require 'chefspec'

describe 'windowsos::time' do
 let(:chef_run) do
    ChefSpec::Runner.new(step_into: ['time']) do |node|
      
      node.set[:workorder][:cloud][:ciName] = "dev-ndc1"
      node.set[:workorder][:services] = "{\"ntp\": {
        \"dev-ndc1\": {
          \"ciAttributes\": {
            \"servers\": \"[ \"time.windows.com\" ]\"
          }\",
          \"ciName\": \"ntp-ndc\"}"
      
    end.converge(described_recipe)
  end
    it 'restarts w32tm service when zone is CST' do
    expect(chef_run).to start_service('w32time')
  end

end
