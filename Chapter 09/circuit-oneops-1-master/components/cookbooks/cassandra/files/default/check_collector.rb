#!/usr/bin/env ruby

require 'rubygems'
require 'json'

collector_port = ARGV[0] || "35853"
web_port = ARGV[1] || "35862"

netstat_rows = `netstat -an | grep #{collector_port}`.to_s.split("\n")
# total connections
connections = netstat_rows.size
connections_backlogged = 0
netstat_rows.each do |row|
  connections_backlogged += 1 if row !~ /0      0/
end

metrics = JSON.parse(`curl -s http://localhost:#{web_port}/node/reports/localhost`)
events = metrics["source.CollectorSource.number of events"]
metrics = JSON.parse(`curl -s http://localhost:#{web_port}/node/reports`)


jvm_used = metrics["jvmInfo"]["mem.heap.used"]
jvm_max = metrics["jvmInfo"]["mem.heap.max"]

jvm_pct_f = 100 - (100 * (jvm_used.to_f / jvm_max.to_f))
jvm_pct = sprintf "%.2f", jvm_pct_f



perf_data = "jvm_percent_free=#{jvm_pct} events=#{events} connections=#{connections} connections_backlogged=#{connections_backlogged} "

puts "#{perf_data} | #{perf_data}"
