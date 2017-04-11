service "postgresql" do
  pattern "postgres: writer"
  action [ :stop, :disable ]
end

if node.platform == "redhat"
  # /etc/init.d/postgresql-9.1 doesnt stop postgres - the pkill does tho
  `pkill -fu postgres`
end
