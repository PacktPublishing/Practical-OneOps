# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# create answer file
inductor = node.workorder.rfcCi

inductor_name = inductor[:ciName]
inductor_home = inductor[:ciAttributes][:inductor_home]

# cert
directory "#{inductor_home}/certs"
file "#{inductor_home}/certs/#{inductor_name}" do
  content inductor[:ciAttributes][:cert]
end

# cert for perf-agents
file "#{inductor_home}/certs/perf_collector_cert.crt" do
  content inductor[:ciAttributes][:perf_collector_cert]
end

cmd = "inductor add "
cmd += "--mqhost #{inductor[:ciAttributes][:mqhost]} "
cmd += "--dns #{inductor[:ciAttributes][:dns]} "
cmd += "--debug #{inductor[:ciAttributes][:debug]} "
cmd += "--daq_enabled true "
cmd += "--collector_domain #{inductor[:ciAttributes][:collector_domain]} "
cmd += "--tunnel_metrics off "
cmd += "--perf_collector_cert #{inductor_home}/certs/perf_collector_cert.crt "
cmd += "--ip_attribute #{inductor[:ciAttributes][:ip]} "
cmd += "--queue #{inductor[:ciAttributes][:queue]} "
cmd += "--mgmt_url #{inductor[:ciAttributes][:url]} "
cmd += "--logstash_cert_location #{inductor_home}/certs/#{inductor_name} "
cmd += "--logstash_hosts #{inductor[:ciAttributes][:logstash_hosts]} "
cmd += "--max_consumers #{inductor[:ciAttributes][:max]} "
cmd += "--local_max_consumers #{inductor[:ciAttributes][:maxlocal]} "
cmd += "--authkey #{inductor[:ciAttributes][:authkey]} "
cmd += "--additional_java_args \"#{inductor[:ciAttributes][:additional_java_args]}\" "
cmd += "--env_vars \"#{inductor[:ciAttributes][:env_vars]}\" "
cmd += "--amq_truststore_location #{inductor[:ciAttributes][:amq_truststore_location]} "

# add/update inductor queue
execute cmd do
  cwd inductor_home
  user "ooadmin"
end
