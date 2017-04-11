service "glusterd" do
  supports :restart => true, :status => true
  action [ :stop, :disable ]
end