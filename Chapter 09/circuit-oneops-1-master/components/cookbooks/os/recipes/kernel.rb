# limits.conf
limits_entries = {}
if node.workorder.rfcCi.ciAttributes.has_key?("limits") &&
   !node.workorder.rfcCi.ciAttributes.limits.empty?

  limits_entries = JSON.parse(node.workorder.rfcCi.ciAttributes.limits)
end
template_variables = {
  :limits_entries    => limits_entries
}

template "/etc/security/limits.d/oneops.conf" do
  source "oneops.conf.erb"
  variables template_variables
  owner "root"
  group "root"
  mode 0644
  not_if { node.platform == "suse" }
end

# sysctl.conf
ruby_block 'update systcl.conf' do
  block do
    sysctl_entries = {}
    if node.workorder.rfcCi.ciAttributes.has_key?("sysctl") &&
       !node.workorder.rfcCi.ciAttributes.sysctl.empty?

      sysctl_entries = JSON.parse(node.workorder.rfcCi.ciAttributes.sysctl)
    end
    tmp_file = Tempfile.new("sysctl.tmp")
    File.open("/etc/sysctl.conf", 'r') do |f|
        f.each_line do |line|
          if(line.match(/^\s*(#|$)/))
            tmp_file.puts line
          else
            key = line.split("=")[0].strip
            if(sysctl_entries.has_key?(key))
              tmp_file.puts line.gsub(line.split("=")[1].to_s.strip,sysctl_entries.delete(key))
            else
              tmp_file.puts line
            end
          end
        end
    end
   if(!sysctl_entries.empty?)
    tmp_file.puts "\n# Pangaea standard kernel params\n"
    sysctl_entries.each_pair do |item, value|
      tmp_file.puts "#{item}" + " = " + "#{value}"
    end
   end
   FileUtils.mv(tmp_file.path, "/etc/sysctl.conf")
   tmp_file.close
   tmp_file.unlink
  end
end

# Load the updated sysctl settings
execute "sysctl -e -p" 
