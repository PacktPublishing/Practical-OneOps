#
# postgresql::snapshot_upload_rsync
#

args = JSON.parse(node.workorder.arglist)    
remote_dir = args["remote_dir"] || 'snapshot'
remote_user = args["remote_user"]
remote_hosts = args["remote_hosts"]

remote_hosts.each do |host|
  cmd = "rsync -a #{node[:tar]} #{user}@#{host}:#{path}"
  Chef::Log.info(cmd)
  execute cmd
end
