#!/usr/bin/env ruby

require 'rubygems'
require 'json'

collector_port = ARGV[0] || "5000"

netstat_rows = `netstat -an | grep #{collector_port}`.to_s.split("\n")
# total connections
connections = netstat_rows.size
connections_backlogged = 0
netstat_rows.each do |row|
  connections_backlogged += 1 if row !~ /0      0/
end

metric_file_name = "/var/run/logstash_metric"
if File.exist?(metric_file_name) && File.mtime(metric_file_name) > Time.now - 30
    events= File.read(metric_file_name).strip.to_i 
    perf_data = "eps=#{events} connections=#{connections} connections_backlogged=#{connections_backlogged}"
else
    perf_data = "eps=0 connections=#{connections} connections_backlogged=#{connections_backlogged}"
end

puts "#{perf_data} | #{perf_data}"
