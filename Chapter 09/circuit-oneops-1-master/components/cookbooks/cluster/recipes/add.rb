#
# Cookbook Name:: cluster
# Recipe:: add
#

# number retries for backend calls
max_retry_count = 5
group_map = Hash.new
is_primary = false
is_active_active = false
is_ip_based = true
if node.workorder.rfcCi.ciAttributes.shared_type == 'dns'
  is_ip_based = false
end
shared_ip = nil
zone_domain = node.dns_domain

# set of primatives to map to a group
extra_primitives = ""


avail_zone = node.workorder.zone.ciName.split(".")[1]
r =  /(.*\d)[a-z]$/
m = r.match avail_zone
region = ''
if m != nil
  region = m[1]
end

if node.workorder.zone.ciAttributes.has_key?("region")
  region = node.workorder.zone.ciAttributes.region
end    

platformName =  node.workorder.box.ciName


# string used to build the config - gen primitives separate to sort/align
primative_cfg = ""
order_cfg = ""
group_cfg = ""
cfg = ""

mysql_service_name = value_for_platform([ "centos", "redhat", "suse", "fedora" ] => {"default" => "mysqld"}, "default" => "mysql")



ruby_block 'check primary' do
  block do

    if ::File.exists?("/proc/drbd")
      drbd_out = `cat /proc/drbd`
      Chef::Log.info("got drbd: "+drbd_out)
      if drbd_out =~ / ro:(.*)\/(.*) ds:(.*?)\/(.*?) /
        if $1 == "Primary"          
          is_primary = true
        end
        
        # both nodes are in Secondary state lets promote the uptodate one
        if $1 == $2 && $3 == "UpToDate"
          `drbdadm primary all`
          is_primary = true
          Chef::Log.info("called: drbdadm primary all")
        end
        
      end
    else 
      if node.workorder.rfcCi.ciName[-1,1] == '1'
        is_primary = true
      end
    end    
    
  end
end

ruby_block 'gen dns resource' do
  not_if { is_ip_based }
  block do
    primative_cfg += "primitive dns lsb:cluster-by-dns"    
    primative_cfg += " op start timeout=\"300\"\n"
    extra_primitives += "dns "
  end
end

ruby_block 'gen shared ip' do
  only_if { is_ip_based }
  block do
    
    conn = Fog::Compute.new(:provider => 'AWS', :region => region,
      :aws_access_key_id => node.workorder.token.ciAttributes.key,
      :aws_secret_access_key => node.workorder.token.ciAttributes.secret )
      
    ip_row = (`ifconfig eth0`).split("\n")[1]
    ip = ip_row.scan(/inet addr:(\d+\.\d+\.\d+\.\d+)/)[0][0]
    Chef::Log.info("ip:"+ip)
    instance_id = ""
    computes = node["workorder"]["payLoad"]["ManagedVia"]
    computes.each do |compute|
      if compute["ciAttributes"]["private_ip"] == ip
        instance_id = compute["ciAttributes"]["instance_id"]
      end
    end
    puts "instance_id:"+instance_id
    server = conn.servers.get(instance_id)
    puts "server:"+server.inspect
    addresses = conn.addresses.all
    has_ip = false
    has_unused_ip = false
    exit_for_public_ip_change = false
    new_eip = nil
    addresses.each do |addr|
      if addr.server_id == instance_id
        has_ip = true
        puts "has shared_ip:"+addr.inspect
        shared_ip = addr
      elsif addr.server_id == nil
        has_unused_ip = true
        new_eip = addr
      end
    end

    if has_unused_ip && !has_ip
      puts "using unused shared_ip:"+new_eip.inspect
      new_eip.server = server
      shared_ip = new_eip
      exit_for_public_ip_change = true
    elsif !has_unused_ip
      shared_ip = conn.addresses.create
      shared_ip.server = server
      puts "created shared_ip:"+shared_ip.inspect
      exit_for_public_ip_change = true
    end
        
    puts "***RESULT:shared_ip="+shared_ip.public_ip
    puts "***RESULT:dns_record="+shared_ip.public_ip
        
    # using ip1 ocf cmd to get ip value to the lsb elastic-ip script
    primative_cfg += "primitive ip1 ocf:heartbeat:IPaddr2 params ip=\"#{shared_ip.public_ip}\" nic=\"eth0:0\"\n"
    primative_cfg += "primitive eip lsb:elastic-ip\n"
    order_cfg += "order eip_after_ip1 inf: ip1 eip\n"    
    cfg += "colocation eip_on_ip1 inf: eip ip1\n"    
    extra_primitives += "ip1 eip "

  end
end

ruby_block 'assemble pacemaker cfg' do
  block do   

    # dynamic payload defined in the pack to get the resources    
    dependencies = node.workorder.payLoad.crm_resources  
    # add storage to the set
    storage_set = node.workorder.payLoad.crm_storage
    if storage_set != nil
      dependencies.push storage_set.first
    end

    dependencies.each do |depends_on|
      class_name = depends_on["ciClassName"].downcase.gsub("bom\.","")
      if group_map.has_key?(class_name) 

        if class_name == "drbd"
          device = depends_on["ciAttributes"]["device"]
          if device.empty?
            device = depends_on["ciName"]
          end
          device_short = device.split("/").last
          if primative_cfg =~ /primitive #{device_short}/
            #skip dupes
            next
          end
                  
        else 
          #skip dupes
          if class_name != "storage" && class_name != "volume"
            next
          end
        end
      end

      # set map for service disable/stops
      group_map[class_name] = true

      if class_name == "haproxy"      
        primative_cfg += "primitive haproxy lsb:haproxy\n"
        
        if is_active_active 
          cfg += 'clone haproxyActiveActive haproxy meta globally-unique="false"'+"\n"
          # TODO: add dns logic for active-active haproxy ; active-passive is supported initially - prolly need EIP too
        end

      elsif class_name == "storage" && primative_cfg !~ /primitive ebs/
          
        if depends_on["ciAttributes"].has_key?("device_map")
          # convert to , to avoid issue w/ ocf-tester
          device_map = depends_on["ciAttributes"]["device_map"].gsub(" ",",")
          primative_cfg += "primitive ebs ocf:heartbeat:ebs params device_map=\"#{device_map}\""
          primative_cfg += " op start timeout=\"300\" op stop timeout=\"300\" op monitor depth=\"0\" timeout=\"30\" interval=\"10\"\n"

          order_cfg += "order ebs_after_eip inf: eip ebs\n"
          order_cfg += "order fs_after_ebs inf: ebs fs_db\n"
          cfg += "colocation fs_on_ebs inf: fs_db ebs\n"
          cfg += "colocation ebs_on_eip inf: ebs eip\n"
          extra_primitives += "ebs "
        end
        
      elsif class_name == "volume"
        mount_point = depends_on["ciAttributes"]["mount_point"]
        fs_type = depends_on["ciAttributes"]["fstype"]
        # use the primary ciName
        if depends_on["ciAttributes"].has_key?("device") && depends_on["ciAttributes"]["device"] != ""
          device = depends_on["ciAttributes"]["device"][0..-2]+"1"        
        else 
          device = depends_on["ciBaseAttributes"]["device"][0..-2]+"1"
        end
        # skip ephemeral volumes
        if device !~ /-eph/
          primative_cfg += "primitive fs_db ocf:heartbeat:Filesystem params device=\"#{device}\" directory=\"#{mount_point}\" fstype=\"#{fs_type}\""
          primative_cfg += " op start timeout=\"300\" op stop timeout=\"300\"\n"
          extra_primitives += "fs_db "
        end       
      elsif class_name == "drbd"
        device = depends_on["ciAttributes"]["device"]
        if device.empty?
          device = depends_on["ciName"]
        end
        device_short = device.split("/").last
        primative_cfg += "primitive #{device_short} ocf:linbit:drbd params drbd_resource=\"#{device_short}\"\n"          
        primative_cfg += "primitive fs_db ocf:heartbeat:Filesystem params device=\"/dev/drbd/by-res/#{device_short}\" directory=\"/db\" fstype=\"xfs\"\n"        

        # make sure its unmounted and out of fstab
        `umount /data`
        `egrep -v "\/data" /etc/fstab > /tmp/fstab`
        `mv /tmp/fstab /etc/fstab`        

      elsif class_name == "oracle"
        
        depends = node.workorder.payLoad.crm_resources
        oracleCi = nil
        depends.each do |dependent|
          if dependent["ciClassName"] =~ /Oracle/
            oracleCi = dependent
          end
        end
        
        if oracleCi == nil         
          Chef::Log.info("cannot find oracle ci for sid and home")
          exit 1
        end
        
        oracle_home = oracleCi["ciAttributes"]["oracle_home"]
        sid = oracleCi["ciAttributes"]["sid"]
        
        primative_cfg += "primitive oracle_ora ocf:heartbeat:oracle params home=\"#{oracle_home}\" sid=\"#{sid}\" user=\"oracle\"\n"
        primative_cfg += "primitive oralsnr_ora ocf:heartbeat:oralsnr params home=\"#{oracle_home}\" sid=\"#{sid}\" user=\"oracle\"\n"

        dependencies.each do |dep|

          dep_class = dep[:ciClassName]
          dep_name = dep[:ciName]

          if dep_name[-1,1] == "1"  
            if dep_class =~ /Drbd/
              cfg += "colocation oracle_on_drbd inf: oracle ms_#{dep_name}:Master\n"
              order_cfg += "order oracle_after_drbd inf: ms_#{dep_name}:promote oracle:start\n"
            elsif dep_class =~ /Storage/
              cfg += "colocation oracle_on_fs inf: oracle_ora fs_db\n"
              cfg += "colocation lsnr_on_ora inf: oralsnr_ora oracle_ora\n"
              order_cfg += "order oracle_after_fs inf: fs_db oracle_ora\n"
              extra_primitives += "ebs "
            end
          end
          
        end

        group_cfg += "group oracle #{extra_primitives} oracle_ora oralsnr_ora\n"  
        
        #make sure its shutdown - using sqlplus to have more control than dbstart/shut
        `echo -e "shutdown abort;\nexit" > /tmp/shutdown_db.sql` 
        Chef::Log.info(`sudo su - oracle -c "source ~oracle/.bashrc ; sqlplus / as sysdba @/tmp/shutdown_db ; lsnrctl stop"`)        

      elsif class_name == "mysql"
        
        # needs binary and datadir
        primative_cfg += "primitive mysqld ocf:heartbeat:mysql params binary=\"/usr/bin/mysqld_safe\" datadir=\"/db\""
        primative_cfg += " op start timeout=\"120\" op stop timeout=\"120\" op monitor depth=\"0\" timeout=\"30\" interval=\"10\"\n"
        group_cfg += "mysql"  
        order_cfg += "order mysql_after_fs inf: fs_db mysqld\n"
        cfg +="colocation mysql_on_fs inf: mysqld fs_db\n"

        if cfg =~ /(drbd\d+)/
          drbd_instance = $1
          cfg += "colocation mysql_on_drbd inf: mysql ms_#{drbd_instance}:Master\n"
          order_cfg += "order mysql_after_drbd inf: ms_#{drbd_instance}:promote mysql:start\n"
        end
        

        if ::File.exists?("/etc/init.d/mysql") == false
          `echo 'service mysqld $1' > /etc/init.d/mysql`            
          `chmod +x /etc/init.d/mysql`
       end

      elsif class_name == "postgresql"
        # primative_cfg += 'primitive postgresqld ocf:heartbeat:pgsql op monitor depth="0" timeout="30" interval="30"'+"\n"
        primative_cfg += "primitive postgresqld lsb:postgresql\n"
        order_cfg += "order postgresql_after_fs inf: fs_db postgresqld\n"
        group_cfg += "postgresql"  
        cfg +="colocation postgres_on_fs inf: postgresqld fs_db\n"

        if cfg =~ /(drbd\d+)/
          drbd_instance = $1
          cfg += "colocation postgres_on_drbd inf: postgresql ms_#{drbd_instance}:Master\n"
          order_cfg += "order postgres_after_drbd inf: ms_#{drbd_instance}:promote postgresql:start\n"
        end

      elsif class_name == "nfs"
        primative_cfg += "primitive nfsd lsb:nfs-kernel-server\n"
        group_cfg += "group nfs fs_db nfsd\n"
        
        if cfg =~ /(drbd\d+)/
          drbd_instance = $1
          cfg += "colocation nfs_on_drbd inf: nfs ms_#{drbd_instance}:Master\n"
          order_cfg += "order nfs_after_drbd inf: ms_#{drbd_instance}:promote nfs:start\n"       
        end
        
      elsif class_name == "activemq"
        primative_cfg += "primitive activemqd lsb:activemq\n"
        group_cfg += "group activemq fs_db activemqd\n"
        
        if cfg =~ /(drbd\d+)/
          drbd_instance = $1
          cfg += "colocation activemq_on_drbd inf: activemq ms_#{drbd_instance}:Master\n"
          order_cfg += "order activemq_after_drbd inf: ms_#{drbd_instance}:promote activemq:start\n"       
        end
        
        # needed for the wrapper script activemq uses
        version = ""
        deps = node.workorder.payLoad.crm_resources
        deps.each do |dep|
          if dep["ciClassName"] =~ /Activemq/
            version = dep["ciAttributes"]["version"]
          end
        end
        activemq_home = "#{node['activemq']['home']}/apache-activemq-#{version}"
        Chef::Log.info("ln -s #{activemq_home}/bin/linux/activemq /etc/init.d/activemq ...")
        `mv -f /etc/init.d/activemq #{activemq_home}/bin/linux/activemq`
        `ln -s #{activemq_home}/bin/linux/activemq /etc/init.d/activemq`
        
      end
    end
    
    if cfg =~ /(drbd\d+)/
      drbd_instance = $1
      if is_ip_based      
        cfg += "colocation eip_on_drbd inf: eip ms_#{drbd_instance}:Master\n"  
      else
        cfg += "colocation dns_on_drbd inf: dns ms_#{drbd_instance}:Master\n" 
      end
    end  
    
    cfg += 'property $id="cib-bootstrap-options" no-quorum-policy="ignore" stonith-enabled="false"'+"\n"      
    # ex: group mysql ip1 eip ebs fs_db mysqld
    # group_cfg_generated = "group #{group_cfg} #{extra_primitives} #{group_cfg}d\n"
    group_cfg_generated = ""
    block = primative_cfg + group_cfg_generated + order_cfg + cfg
    File.open('/opt/oneops/crm_conf', 'w') {|f| f.write(block) }
    Chef::Log.info("cfg:\n"+block)

  end
end

ruby_block 'cleanup crm' do
  block do   

  #crm_status = `cibadmin -E --force`
  
  end
end

service "haproxy" do
  action [ :stop, :disable ]
  only_if { group_map.has_key?("haproxy") }
end


service mysql_service_name do
  action [ :stop, :disable ]
  only_if { group_map.has_key?("mysql") }
end


service "postgresql" do
  action [ :stop, :disable ]
  only_if { group_map.has_key?("postgresql") }
end

service "activemq" do
  action [ :stop, :disable ]
  only_if { group_map.has_key?("activemq") }
end


ruby_block 'bootstrap crm' do
  block do
    # note: theres an only_if is_primary || is_active_active at the bottom of this block

    # does base cip
    cmd = "crm configure exit"
    Chef::Log.info("#{cmd}: "+`#{cmd}`)
      
    is_up = false
    retry_count = 0
    max_retry_count = 4
    # another loop to wait for heartbeat & pacemaker to sync
    while !is_up && retry_count <max_retry_count
      node_count = (`crm node status | wc -l`).chop.to_i
      Chef::Log.info("crm node status count:"+node_count.to_s)
      if node_count > 3
        is_up = true
      else
        Chef::Log.info("waiting 10s then will try again...")
       `sleep 10`
      end
      retry_count +=1
    end
    if retry_count == max_retry_count
      Chef::Log.error("tried for 2min to get nodes to talk to eachother ...giving up")
      exit 1
    end
    
    
    is_crm_happy = false
    retry_count = 0
    max_retry_count = 10
    cmd = "crm configure < /opt/oneops/crm_conf 2>&1"
    Chef::Log.info("#{cmd} ...")    
    # initial communication sync can take awhile
    while !is_crm_happy && retry_count <max_retry_count
      out = `#{cmd}`
      #$? is a Process::Status object
      exit_code = $?.to_i
      Chef::Log.info("#{cmd}: "+out)

      # remove non critical errors
      a = out.gsub(/ERROR.*already in use/,"")
      out = a.gsub(/ERROR: CIB erase aborted \(nothing was deleted\)/,"")
      Chef::Log.info("post error cleanup:"+out)
      
      
      # sometimes crm has errors with an exit code of 0
      if (out !~ /ERROR/)
        is_crm_happy = true        
        Chef::Log.info("sleeping 30s because crm takes some time to bringup everything...")
        sleep(30)
      else
        Chef::Log.info("sleeping 10s because: "+out)
        sleep(10)
        # try to cleanup
        Chef::Log.info("cleanup: crm configure erase:"+`crm configure erase 2>&1`)          
      end
      retry_count +=1
    end
    if retry_count == max_retry_count
      Chef::Log.error("tried for 2min to get nodes to talk to eachother ...giving up")
      exit 1
    end
      
    
  end
  
  only_if { is_primary || is_active_active }  
end
