
group node['graphite']['account']['group'] do
    system true
    action :create
    only_if "getent group node['graphite']['account']['group']"
end

user node['graphite']['account']['user'] do
    system true
    group node['graphite']['account']['group']
    home node['graphite']['install_path']
    shell "/sbin/nologin"
    action :create
    only_if "getent passwd node['graphite']['account']['group']"
end