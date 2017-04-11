include_recipe "glusterfs::add"

ci = node.workorder.rfcCi
parent = node.workorder.payLoad.RealizedAs[0]
replicas = ci.ciAttributes[:replicas].to_i
compute_index = ci[:ciName].split('-').last.to_i
cloud_index = ci[:ciName].split('-').reverse[1].to_i
# get all computes in all clouds
computes = node.workorder.payLoad.RequiresComputes
volstore_prefix = "#{ci.ciAttributes[:store]}/#{parent[:ciName]}"

ruby_block "volume replace #{parent[:ciName]}" do
    block do
      bricks = {}
      computes.each do |c|
        compute_bricks = find_bricks(c[:ciName].split('-').last.to_i,replicas,computes.length)
        Chef::Log.info("Bricks for #{c[:ciName]} (#{c.ciAttributes[:private_ip]}) #{compute_bricks.inspect}")
        compute_bricks.each do |b|
          bricks[b] = "#{c.ciAttributes[:private_ip]}:#{volstore_prefix}/#{b}"
        end
      end
    
      tf1 = Tempfile.new("tmp1.txt")
      tf2 = Tempfile.new("tmp2.txt")
    
      %x(gluster volume info #{parent[:ciName]} > tf1)
      %x(grep "^Brick[0-9]" tf1 > tf2)
      brick_arr = %x(awk '{print $2}' tf2).split("\n")
      old_brick_map = Hash.new
      brick_arr.each {|b| old_brick_map[b.split(":")[1]]=[b.split(":")[0]]}
    
      bricks.each do |brick|
        vol_p = brick[1]
        if(vol_p.include? ":")
          barr = vol_p.split(":")
          ip = barr[0]
          vol_path = barr[1]
          old_ip = old_brick_map[vol_path]
          puts "old_ip:#{old_ip} ip:#{ip} path:#{vol_path}"
          if old_ip != ip
            Chef::Log.info("volume replace-brick #{parent[:ciName]} #{old_ip}:#{vol_path} #{ip}:#{vol_path}")
            replace_res = `yes y | gluster volume replace-brick #{parent[:ciName]} #{old_ip}:#{vol_path} #{ip}:#{vol_path} commit force`
            Chef::Log.info(replace_res)
            detach_res = detach_old_ip = `yes y | gluster peer detach #{old_ip} force`
            Chef::Log.info(detach_res)
          end
        end
      end  
   end
 end
