#!/usr/bin/env ruby

raw_get_pods=`kubectl get pods --all-namespaces`.split("\n")
raw_get_pods.shift
running_count = 0
pending_count = 0
crash_count = 0
total_count = 0
raw_get_pods.each do |pod|
  total_count += 1
  case pod
  when /\sPending\s/
    pending_count += 1
  when /\sRunning\s/
    running_count += 1
  when /\sCrashLoopBackOff\s/
    crash_count += 1
  end
end

percent_running = 100 * (running_count.to_f / total_count.to_f)

puts "ok|percent_running=#{percent_running.round(2)} running=#{running_count} pending=#{pending_count} crash=#{crash_count} total=#{total_count}"

