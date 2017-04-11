# Couchbase monitoring file
cookbook_file '/opt/nagios/libexec/check_couchbase.py' do
    source 'check_couchbase.py'
    owner 'root'
    group 'root'
    mode 0755
end