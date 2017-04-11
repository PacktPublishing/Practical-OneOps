if node.platform != "ubuntu"
  execute "sudo pkill -f '^/usr/sbin/postfix -d' ; service postfix restart"
end
  