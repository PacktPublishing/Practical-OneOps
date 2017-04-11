windows_service 'W3SVC' do
  action [:stop, :start]
end
