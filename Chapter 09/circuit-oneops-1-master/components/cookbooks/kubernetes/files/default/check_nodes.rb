#!/usr/bin/env ruby

raw_get_nodes=`kubectl get nodes`.split("\n")
raw_get_nodes.shift
ready_count = 0
total_count = 0
raw_get_nodes.each do |node|
  total_count += 1
  if node =~ /\sReady\s/
    ready_count += 1
  end
end

percent_ready = 100 * (ready_count.to_f / total_count.to_f)

puts "ok|percent_ready=#{percent_ready.round(2)} ready=#{ready_count} total=#{total_count}"

